#!/bin/sh

# This scripts assumes *a lot*
# Run it once, as soon as you've booted the vagrant environment:

# vagrant up
# vagrant ssh controller
# /vagrant/demo.sh

# Yes, that's it!

# Crude lock to prevent multiple runs
if [[ -f ~/.demo.lock ]]
then
	echo "~/.demo.lock in place. Already ran. Exiting."
	exit 1
else
	touch ~/.demo.lock
fi

export OS_TENANT_NAME=cookbook
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL=https://192.168.100.200:5000/v2.0/
export OS_NO_CACHE=1
export OS_KEY=/vagrant/cakey.pem
export OS_CACERT=/vagrant/ca.pem

# Aliases for insecure SSL
alias nova='nova --insecure'
alias keystone='keystone --insecure'
alias neutron='neutron --insecure'
alias glance='glance --insecure'
alias cinder='cinder --insecure'

TENANT_ID=$(keystone tenant-list \
   | awk '/\ cookbook\ / {print $2}')

neutron net-create \
    --tenant-id ${TENANT_ID} \
    cookbook_network_1


neutron subnet-create \
    --tenant-id ${TENANT_ID} \
    --name cookbook_subnet_1 \
    cookbook_network_1 \
    10.200.0.0/24

neutron router-create \
    --tenant-id ${TENANT_ID} \
    cookbook_router_1

ROUTER_ID=$(neutron router-list \
  | awk '/\ cookbook_router_1\ / {print $2}')

SUBNET_ID=$(neutron subnet-list \
  | awk '/\ cookbook_subnet_1\ / {print $2}')

neutron router-interface-add \
    ${ROUTER_ID} \
    ${SUBNET_ID}

nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

# Fix m1.tiny
nova flavor-delete 1
nova flavor-create m1.tiny 1 512 0 1

ssh-keygen -t rsa -f demokey -N ""

nova keypair-add --pub-key demokey.pub demokey
rm -f /vagrant/demokey
cp demokey /vagrant

UBUNTU=$(nova image-list \
  | awk '/\ trusty/ {print $2}')

NET_ID=$(neutron net-list | awk '/cookbook_network_1/ {print $2}')

# If Cinder is available, boot from vol
if ping -c 1 cinder
then
	nova boot --flavor m1.tiny --block-device source=image,id=${UBUNTU},shutdown=preserve,dest=volume,size=15,bootindex=0 --key_name demokey --nic net-id=${NET_ID} --config-drive=true CookbookInstance1
# Else ephemeral
else
	nova boot --flavor 1 --image ${UBUNTU} --key_name demokey --nic net-id=${NET_ID} CookbookInstance1
fi

# Create an external network of type Flat (which goes out of eth3)
neutron net-create --tenant-id ${TENANT_ID} floatingNet --shared --provider:network_type flat --provider:physical_network eth3 --router:external=True

# Subnet matches subnet of eth3: 192.168.100.0/24, but we assign a small portion for floating IPs
neutron subnet-create --tenant-id ${TENANT_ID} --name cookbook_float_subnet_1 --allocation-pool start=192.168.100.10,end=192.168.100.20 --gateway 192.168.100.1 floatingNet 192.168.100.0/24 --enable_dhcp=False


ROUTER_ID=$(neutron router-list \
  | awk '/\ cookbook_router_1\ / {print $2}')

EXT_NET_ID=$(neutron net-list \
  | awk '/\ floatingNet\ / {print $2}')

neutron router-gateway-set \
    ${ROUTER_ID} \
    ${EXT_NET_ID}

neutron floatingip-create --tenant-id ${TENANT_ID} floatingNet
VM_PORT=$(neutron port-list | awk '/10.200.0.2/ {print $2}')
FLOAT_ID=$(neutron floatingip-list | awk '/192.168.100.11/ {print $2}')
neutron floatingip-associate ${FLOAT_ID} ${VM_PORT}
