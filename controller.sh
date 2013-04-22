#!/bin/bash

# controller.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

# The routeable IP of the node is on our eth1 interface
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

#export LANG=C

# MySQL
export MYSQL_HOST=$MY_IP
export MYSQL_ROOT_PASS=openstack
export MYSQL_DB_PASS=openstack

echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password seen true" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again seen true" | sudo debconf-set-selections

sudo apt-get -y install mysql-server python-mysqldb

sudo sed -i "s/^bind\-address.*/bind-address = 0.0.0.0/g" /etc/mysql/my.cnf
sudo sed -i "s/^#max_connections.*/max_connections = 512/g" /etc/mysql/my.cnf

sudo restart mysql

# Ensure root can do its job
mysql -u root --password=${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"localhost\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
mysql -u root --password=${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"${MYSQL_HOST}\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
mysql -u root --password=${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"%\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"

mysqladmin -uroot -p${MYSQL_ROOT_PASS} flush-privileges

######################
# Chapter 1 KEYSTONE #
######################

# Create database
sudo apt-get -y install keystone python-keyring

MYSQL_ROOT_PASS=openstack
MYSQL_KEYSTONE_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE keystone;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'keystone'@'%' = PASSWORD('$MYSQL_KEYSTONE_PASS');"

sudo sed -i "s#^connection.*#connection = mysql://keystone:openstack@${MYSQL_HOST}/keystone#" /etc/keystone/keystone.conf

sudo sed -i 's/^# admin_token.*/admin_token = ADMIN/' /etc/keystone/keystone.conf

sudo stop keystone
sudo start keystone

sudo keystone-manage db_sync

sudo apt-get -y install python-keystoneclient

export ENDPOINT=${MY_IP}
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0

# admin role
keystone role-create --name admin

# Member role
keystone role-create --name Member

keystone tenant-create --name cookbook --description "Default Cookbook Tenant" --enabled true

TENANT_ID=$(keystone tenant-list | awk '/\ cookbook\ / {print $2}')

export PASSWORD=openstack
keystone user-create --name admin --tenant_id $TENANT_ID --pass $PASSWORD --email root@localhost --enabled true

TENANT_ID=$(keystone tenant-list | awk '/\ cookbook\ / {print $2}')

ROLE_ID=$(keystone role-list | awk '/\ admin\ / {print $2}')

USER_ID=$(keystone user-list | awk '/\ admin\ / {print $2}')

keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID

# Create the user
PASSWORD=openstack
keystone user-create --name demo --tenant_id $TENANT_ID --pass $PASSWORD --email demo@localhost --enabled true

TENANT_ID=$(keystone tenant-list | awk '/\ cookbook\ / {print $2}')

ROLE_ID=$(keystone role-list | awk '/\ Member\ / {print $2}')

USER_ID=$(keystone user-list | awk '/\ demo\ / {print $2}')

# Assign the Member role to the demo user in cookbook
keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID

# OpenStack Compute Nova API Endpoint
keystone service-create --name nova --type compute --description 'OpenStack Compute Service'

# OpenStack Compute EC2 API Endpoint
keystone service-create --name ec2 --type ec2 --description 'EC2 Service'

# Glance Image Service Endpoint
keystone service-create --name glance --type image --description 'OpenStack Image Service'

# Keystone Identity Service Endpoint
keystone service-create --name keystone --type identity --description 'OpenStack Identity Service'

# Cinder Block Storage Endpoint
keystone service-create --name volume --type volume --description 'Volume Service'

# Quantum Network Service Endpoint
keystone service-create --name network --type network --description 'Quantum Network Service'

# OpenStack Compute Nova API
NOVA_SERVICE_ID=$(keystone service-list | awk '/\ nova\ / {print $2}')

PUBLIC="http://$ENDPOINT:8774/v2/\$(tenant_id)s"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC

keystone endpoint-create --region RegionOne --service_id $NOVA_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# OpenStack Compute EC2 API
EC2_SERVICE_ID=$(keystone service-list | awk '/\ ec2\ / {print $2}')

PUBLIC="http://$ENDPOINT:8773/services/Cloud"
ADMIN="http://$ENDPOINT:8773/services/Admin"
INTERNAL=$PUBLIC

keystone endpoint-create --region RegionOne --service_id $EC2_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# Glance Image Service
GLANCE_SERVICE_ID=$(keystone service-list | awk '/\ glance\ / {print $2}')

PUBLIC="http://$ENDPOINT:9292/v1"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC

keystone endpoint-create --region RegionOne --service_id $GLANCE_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# Keystone OpenStack Identity Service
KEYSTONE_SERVICE_ID=$(keystone service-list | awk '/\ keystone\ / {print $2}')

PUBLIC="http://$ENDPOINT:5000/v2.0"
ADMIN="http://$ENDPOINT:35357/v2.0"
INTERNAL=$PUBLIC

keystone endpoint-create --region RegionOne --service_id $KEYSTONE_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# Cinder Block Storage Service
CINDER_SERVICE_ID=$(keystone service-list | awk '/\ volume\ / {print $2}')
CINDER_ENDPOINT="172.16.0.211"
PUBLIC="http://$CINDER_ENDPOINT:8776/v1/%(tenant_id)s"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC

keystone endpoint-create --region RegionOne --service_id $CINDER_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# Quantum Network Service
QUANTUM_SERVICE_ID=$(keystone service-list | awk '/\ network\ / {print $2}')

PUBLIC="http://$ENDPOINT:9696/"
ADMIN=$PUBLIC
INTERNAL=$PUBLIC

keystone endpoint-create --region RegionOne --service_id $QUANTUM_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

# Service Tenant
keystone tenant-create --name service --description "Service Tenant" --enabled true

SERVICE_TENANT_ID=$(keystone tenant-list | awk '/\ service\ / {print $2}')

keystone user-create --name nova --pass nova --tenant_id $SERVICE_TENANT_ID --email nova@localhost --enabled true

keystone user-create --name glance --pass glance --tenant_id $SERVICE_TENANT_ID --email glance@localhost --enabled true

keystone user-create --name keystone --pass keystone --tenant_id $SERVICE_TENANT_ID --email keystone@localhost --enabled true

keystone user-create --name cinder --pass cinder --tenant_id $SERVICE_TENANT_ID --email cinder@localhost --enabled true

keystone user-create --name quantum --pass quantum --tenant_id $SERVICE_TENANT_ID --email quantum@localhost --enabled true

# Get the nova user id
NOVA_USER_ID=$(keystone user-list | awk '/\ nova\ / {print $2}')

# Get the admin role id
ADMIN_ROLE_ID=$(keystone role-list | awk '/\ admin\ / {print $2}')

# Assign the nova user the admin role in service tenant
keystone user-role-add --user $NOVA_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Get the glance user id
GLANCE_USER_ID=$(keystone user-list | awk '/\ glance\ / {print $2}')

# Assign the glance user the admin role in service tenant
keystone user-role-add --user $GLANCE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Get the keystone user id
KEYSTONE_USER_ID=$(keystone user-list | awk '/\ keystone\ / {print $2}')

# Assign the keystone user the admin role in service tenant
keystone user-role-add --user $KEYSTONE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Get the cinder user id
CINDER_USER_ID=$(keystone user-list | awk '/\ cinder \ / {print $2}')

# Assign the cinder user the admin role in service tenant
keystone user-role-add --user $CINDER_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Create quantum service user in the services tenant
QUANTUM_USER_ID=$(keystone user-list | awk '/\ quantum \ / {print $2}')

# Grant admin role to quantum service user
keystone user-role-add --user $QUANTUM_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID


######################
# Chapter 2 GLANCE   #
######################

# Install Service
sudo apt-get update
sudo apt-get -y install glance
#sudo apt-get -y install glance-client # borks because of repo issues. I presume will be fixed.
sudo apt-get -y install python-glanceclient 

# Create database
MYSQL_ROOT_PASS=openstack
MYSQL_GLANCE_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE glance;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'glance'@'%' = PASSWORD('$MYSQL_GLANCE_PASS');"

# glance-api-paste.ini
echo "service_protocol = http
service_host = ${MY_IP}
service_port = 5000
auth_host = ${MY_IP}
auth_port = 35357
auth_protocol = http
auth_uri = http://${MY_IP}:5000/
admin_tenant_name = service
admin_user = glance
admin_password = glance
" | sudo tee -a /etc/glance/glance-api-paste.ini

# glance-api.conf
echo "config_file = /etc/glance/glance-api-paste.ini
flavor = keystone
" | sudo tee -a /etc/glance/glance-api.conf

# glance-registry-paste.ini
echo "service_protocol = http
service_host = ${MY_IP}
service_port = 5000
auth_host = ${MY_IP}
auth_port = 35357
auth_protocol = http
auth_uri = http://${MY_IP}:5000/
admin_tenant_name = service
admin_user = glance
admin_password = glance
" | sudo tee -a /etc/glance/glance-registry-paste.ini

# glance-registry.conf
echo "config_file = /etc/glance/glance-registry-paste.ini
flavor = keystone
" | sudo tee -a /etc/glance/glance-registry.conf

sudo sed -i "s,^sql_connection.*,sql_connection = mysql://glance:${MYSQL_GLANCE_PASS}@${MYSQL_HOST}/glance," /etc/glance/glance-registry.conf
sudo sed -i "s,^sql_connection.*,sql_connection = mysql://glance:${MYSQL_GLANCE_PASS}@${MYSQL_HOST}/glance," /etc/glance/glance-api.conf

sudo stop glance-registry
sudo start glance-registry
sudo stop glance-api
sudo start glance-api

sudo glance-manage db_sync

# Get some images and upload
export OS_TENANT_NAME=cookbook
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://${MY_IP}:5000/v2.0/
export OS_NO_CACHE=1

sudo apt-get -y install wget
# If you have a proxy outside of your VirtualBox environment, use it
if [[ ! -z "$APT_PROXY" ]]
then
	wget --quiet http://${APT_PROXY}/precise-server-cloudimg-amd64-disk1.img        
else
	wget http://uec-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img
fi

glance image-create --name='Ubuntu 12.04 x86_64 Server' --disk-format=qcow2 --container-format=bare --public < precise-server-cloudimg-amd64-disk1.img

#####################
# Quantum           #
#####################
# Install dependencies
sudo apt-get install -y linux-headers-`uname -r` build-essential
sudo apt-get install -y openvswitch-switch openvswitch-datapath-dkms

# Install the network service (quantum)
sudo apt-get install -y quantum-server quantum-plugin-openvswitch

# Install the network service (quantum) agents
sudo apt-get install -y quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent

# Create database
MYSQL_ROOT_PASS=openstack
MYSQL_QUANTUM_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE quantum;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON quantum.* TO 'quantum'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'quantum'@'%' = PASSWORD('$MYSQL_QUANTUM_PASS');"

# Configure the quantum OVS plugin
sudo sed -i "s|sql_connection = sqlite:////var/lib/quantum/ovs.sqlite|sql_connection = mysql://quantum:openstack@${MY_IP}/quantum|g"  /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo sed -i 's/# Default: integration_bridge = br-int/integration_bridge = br-int/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo sed -i 's/# Default: tunnel_bridge = br-tun/tunnel_bridge = br-tun/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo sed -i 's/# Default: enable_tunneling = False/enable_tunneling = True/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo sed -i 's/# Example: tenant_network_type = gre/tenant_network_type = gre/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo sed -i 's/# Example: tunnel_id_ranges = 1:1000/tunnel_id_ranges = 1:1000/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sudo sed -i "s/# Default: local_ip =/local_ip = ${MY_IP}/g" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

# List the new user and role assigment
keystone user-list --tenant-id $SERVICE_TENANT_ID
keystone user-role-list --tenant-id $SERVICE_TENANT_ID --user-id $QUANTUM_USER_ID

# Configure the quantum service to use keystone
sudo cat > /etc/quantum/api-paste.ini <<EOF
[composite:quantum]
use = egg:Paste#urlmap
/: quantumversions
/v2.0: quantumapi_v2_0

[composite:quantumapi_v2_0]
use = call:quantum.auth:pipeline_factory
noauth = extensions quantumapiapp_v2_0
keystone = authtoken keystonecontext extensions quantumapiapp_v2_0

[filter:keystonecontext]
paste.filter_factory = quantum.auth:QuantumKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystone.middleware.auth_token:filter_factory
auth_host = ${MY_IP}
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = quantum
admin_password = quantum

[filter:extensions]
paste.filter_factory = quantum.api.extensions:plugin_aware_extension_middleware_factory

[app:quantumversions]
paste.app_factory = quantum.api.versions:Versions.factory

[app:quantumapiapp_v2_0]
paste.app_factory = quantum.api.v2.router:APIRouter.factory
EOF

sudo cat > /etc/quantum/l3_agent.ini <<EOF
[DEFAULT]
# Show debugging output in log (sets DEBUG log level output)
# debug = True

# L3 requires that an interface driver be set.  Choose the one that best
# matches your plugin.

# OVS based plugins (OVS, Ryu, NEC) that supports L3 agent
interface_driver = quantum.agent.linux.interface.OVSInterfaceDriver
auth_url = http://${MY_IP}:35357/v2.0
auth_region = RegionOne
admin_tenant_name = service
admin_user = quantum
admin_password = quantum
EOF

sudo cat > /etc/quantum/metadata_agent.ini <<EOF
[DEFAULT]
# The Quantum user information for accessing the Quantum API.
auth_url = http://${MY_IP}:35357/v2.0
auth_region = RegionOne
admin_tenant_name = service
admin_user = quantum
admin_password = quantum

# IP address used by Nova metadata server
nova_metadata_ip = ${MY_IP}

# TCP Port used by Nova metadata server
nova_metadata_port = 8775

metadata_proxy_shared_secret = helloOpenStack
EOF

sudo sed -i 's/# auth_strategy = keystone/auth_strategy = keystone/g' /etc/quantum/quantum.conf
sudo sed -i 's/# rabbit_host = localhost/rabbit_host = '${MY_IP}'/g' /etc/quantum/quantum.conf
sudo sed -i 's/auth_host = 127.0.0.1/auth_host = '${MY_IP}'/g' /etc/quantum/quantum.conf
sudo sed -i 's/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/g' /etc/quantum/quantum.conf
sudo sed -i 's/admin_user = %SERVICE_USER%/admin_user = quantum/g' /etc/quantum/quantum.conf
sudo sed -i 's/admin_password = %SERVICE_PASSWORD%/admin_password = quantum/g' /etc/quantum/quantum.conf
sudo sed -i 's/bind_host = 0.0.0.0/bind_host = '${MY_IP}'/g' /etc/quantum/quantum.conf

# Start Open vSwitch
sudo service openvswitch-switch restart

# Create the integration and external bridges
sudo ovs-vsctl add-br br-int
sudo ovs-vsctl add-br br-ex

# Restart Services
cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i restart; done

# Create a network and subnet
TENANT_ID=$(keystone tenant-list | awk '/\ cookbook\ / {print $2}')
PRIVATE_NET_ID=`quantum net-create private | awk '/ id / { print $4 }'`
PRIVATE_SUBNET1_ID=`quantum subnet-create --tenant-id $TENANT_ID --name private-subnet1 --ip-version 4 $PRIVATE_NET_ID 10.0.0.0/29 | awk '/ id / { print $4 }'`

######################
# Chapter 3 COMPUTE  #
######################

# Create database
MYSQL_HOST=${MY_IP}
GLANCE_HOST=${MY_IP}
KEYSTONE_ENDPOINT=${MY_IP}
SERVICE_TENANT=service
SERVICE_PASS=nova

MYSQL_ROOT_PASS=openstack
MYSQL_NOVA_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE nova;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%'"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'nova'@'%' = PASSWORD('$MYSQL_NOVA_PASS');"

sudo apt-get -y install rabbitmq-server nova-api nova-scheduler nova-objectstore dnsmasq nova-conductor

# Clobber the nova.conf file with the following
NOVA_CONF=/etc/nova/nova.conf
NOVA_API_PASTE=/etc/nova/api-paste.ini

cat > /tmp/nova.conf << EOF
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True

api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata

# Libvirt and Virtualization
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
libvirt_type=qemu

# Database
sql_connection=mysql://nova:openstack@${MYSQL_HOST}/nova

# Messaging
rabbit_host=${MYSQL_HOST}

# EC2 API Flags
ec2_host=${MYSQL_HOST}
ec2_dmz_host=${MYSQL_HOST}
ec2_private_dns_show_ip=True

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://${MY_IP}:9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=service
quantum_admin_username=quantum
quantum_admin_password=quantum
quantum_admin_auth_url=http://${MY_IP}:35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

#Metadata
service_quantum_metadata_proxy = True
quantum_metadata_proxy_shared_secret = helloOpenStack
metadata_host = ${MY_IP}
metadata_listen = 127.0.0.1
metadata_listen_port = 8775

# Cinder #
volume_driver=nova.volume.driver.ISCSIDriver
enabled_apis=ec2,osapi_compute,metadata
volume_api_class=nova.volume.cinder.API
iscsi_helper=tgtadm

# Images
image_service=nova.image.glance.GlanceImageService
glance_api_servers=${GLANCE_HOST}:9292

# Scheduler
scheduler_default_filters=AllHostsFilter

# Auth
auth_strategy=keystone
keystone_ec2_url=http://${KEYSTONE_ENDPOINT}:5000/v2.0/ec2tokens

# NoVNC
novnc_enabled=true
novncproxy_base_url=http://${MY_IP}:6080/vnc_auto.html
novncproxy_port=6080
vncserver_proxyclient_address=${MY_IP}
vncserver_listen=0.0.0.0

EOF

sudo rm -f $NOVA_CONF
sudo mv /tmp/nova.conf $NOVA_CONF
sudo chmod 0640 $NOVA_CONF
sudo chown nova:nova $NOVA_CONF

# Paste file
sudo sed -i "s/127.0.0.1/$KEYSTONE_ENDPOINT/g" $NOVA_API_PASTE
sudo sed -i "s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT/g" $NOVA_API_PASTE
sudo sed -i "s/%SERVICE_USER%/nova/g" $NOVA_API_PASTE
sudo sed -i "s/%SERVICE_PASSWORD%/$SERVICE_PASS/g" $NOVA_API_PASTE

sudo nova-manage db sync

sudo stop nova-api
sudo stop nova-scheduler
sudo stop nova-objectstore
sudo stop nova-conductor

sudo start nova-api
sudo start nova-scheduler
sudo start nova-objectstore
sudo start nova-conductor

##########
# Cinder #
##########
# Install the DB
MYSQL_ROOT_PASS=openstack
MYSQL_CINDER_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE cinder;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'cinder'@'%' = PASSWORD('$MYSQL_CINDER_PASS');"

###########
# Horizon #
###########
# Install dependencies
sudo apt-get install -y memcached novnc

# Install the dashboard (horizon)
sudo apt-get install -y --no-install-recommends openstack-dashboard nova-novncproxy

# Set default role
sudo sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${MY_IP}\"/g" /etc/openstack-dashboard/local_settings.py

# Create a .stacrc file
cat > /root/.stackrc <<EOF
export OS_TENANT_NAME=cookbook
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL=http://${MY_IP}:5000/v2.0/
EOF

