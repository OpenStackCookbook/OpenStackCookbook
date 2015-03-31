# swift.sh

# Source in common env vars
. /vagrant/common.sh

# Install some deps
sudo apt-get install -y linux-headers-`uname -r` build-essential python-mysqldb xfsprogs

# The routeable IP of the node is on our eth1 interface
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
KEYSTONE_ENDPOINT=${ETH3_IP}

##############################################
# Chapter 6 - Using OpenStack Object Storage #
##############################################



swift_install() {
	# Install some packages:
	sudo apt-get -y install swift swift-proxy swift-account swift-container swift-object memcached xfsprogs curl python-webob python-keystoneclient python-swiftclient
	sudo service ntp restart

	# Create signing directory & Set owner to swift
	mkdir /var/swift-signing
	chown -R swift /var/swift-signing

	# Create cache directory & set owner to swift
	mkdir -p /var/cache/swift
	chown -R swift:swift /var/cache/swift

}

swift_configure(){

# Create a loopback filesystem
sudo mkdir /mnt/swift
dd if=/dev/zero of=/mnt/swift/swift-volume bs=1 count=0 seek=2G
mkfs.xfs -i size=1024 /mnt/swift/swift-volume

sudo mkdir /mnt/swift_backend
echo '/mnt/swift/swift-volume /mnt/swift_backend xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab
sudo mount -a

#cd /mnt/swift_backend
#sudo mkdir node{1..4}
#sudo chown swift.swift /mnt/swift_backend/*
#for i in {1..4}; do sudo ln -s /mnt/swift_backend/node$i /srv/node$i; done;
#sudo mkdir -p /etc/swift/i{account-server,container-server,object-server}
#/srv/node1/device /srv/node2/device /srv/node3/device /srv/node4/device
#sudo mkdir /run/swift

	# Setup our directory structure
	sudo mkdir /mnt/swift_backend/{1..4}
	sudo chown swift:swift /mnt/swift_backend/*
	sudo ln -s /mnt/swift_backend/{1..4} /srv
	sudo mkdir -p /etc/swift/{object-server,container-server,account-server}
	for S in {1..4}; do sudo mkdir -p /srv/${S}/node/sdb${S}; done
	sudo mkdir -p /var/run/swift
	sudo chown -R swift:swift /etc/swift /srv/{1..4}/
	mkdir -p /var/run/swift
	chown swift:swift /var/run/swift

	# Setup rsync
sudo cat > /etc/rsyncd.conf <<EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 127.0.0.1

[account6012]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/account6012.lock

[account6022]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/account6022.lock

[account6032]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/account6032.lock

[account6042]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/account6042.lock

[container6011]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/container6011.lock

[container6021]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/container6021.lock

[container6031]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/container6031.lock

[container6041]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/container6041.lock

[object6010]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/object6010.lock

[object6020]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/object6020.lock

[object6030]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/object6030.lock

[object6040]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/object6040.lock
EOF

sudo sed -i 's/=false/=true/' /etc/default/rsync
sudo service rsync start

# Setup /etc/swift/swift.conf
SWIFT_HASH=`< /dev/urandom tr -dc A-Za-z0-9_ | head -c16; echo`
sudo cat > /etc/swift/swift.conf  <<EOF
[swift-hash]
# Random unique string used on all nodes
swift_hash_path_suffix=$SWIFT_HASH
EOF

# Configure the Swift Proxy Server
sudo cat > /etc/swift/proxy-server.conf <<EOF
[DEFAULT]
bind_port = 8080
user = swift
swift_dir = /etc/swift
log_level = DEBUG

[pipeline:main]
# Order of execution of modules defined below
pipeline = catch_errors healthcheck cache container_sync authtoken keystone proxy-server

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = true
set log_name = swift-proxy
set log_facility = LOG_LOCAL0
set log_level = INFO
set access_log_name = swift-proxy
set access_log_facility = SYSLOG
set access_log_level = INFO
set log_headers = True

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:cache]
use = egg:swift#memcache
set log_name = cache

[filter:container_sync]
use = egg:swift#container_sync

[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_protocol = https
auth_host = $KEYSTONE_ENDPOINT
auth_port = 35357
auth_token = admin
service_protocol = https
service_host = $KEYSTONE_ENDPOINT
service_port = 5000
admin_token = admin
admin_tenant_name = service
admin_user = swift
admin_password = swift
delay_auth_decision = 0
signing_dir = /var/swift-signing
insecure = True

[filter:keystone]
use = egg:swift#keystoneauth
operator_roles = admin, Member
#reseller_prefix = AUTH_
EOF

# container-sync-realms.conf for container sync
cat > /etc/swift/container-sync-realms.conf <<EOF
[realm1]
key = realm1key
cluster_swift = http://swift:8080/v1/
cluster_swift2 = http://swift2:8080/v1/
EOF


# Setup Account Server
sudo cat > /etc/swift/account-server/1.conf <<EOF
[DEFAULT]
devices = /srv/1/node
mount_check = false
bind_port = 6012
user = swift
log_facility = LOG_LOCAL2

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]
vm_test_mode = yes

[account-auditor]

[account-reaper]

EOF

cd /etc/swift/account-server
sed -e "s/srv\/1/srv\/2/" -e "s/601/602/" -e "s/LOG_LOCAL2/LOG_LOCAL3/" 1.conf | sudo tee -a 2.conf
sed -e "s/srv\/1/srv\/3/" -e "s/601/603/" -e "s/LOG_LOCAL2/LOG_LOCAL4/" 1.conf | sudo tee -a 3.conf
sed -e "s/srv\/1/srv\/4/" -e "s/601/604/" -e "s/LOG_LOCAL2/LOG_LOCAL5/" 1.conf | sudo tee -a 4.conf

# Container Server config
sudo cat > /etc/swift/container-server/1.conf <<EOF
[DEFAULT]
devices = /srv/1/node
mount_check = false
bind_port = 6011
user = swift
log_facility = LOG_LOCAL2

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[account-replicator]
vm_test_mode = yes

[account-updater]

[account-auditor]

[account-sync]

[container-sync]

[container-auditor]

[container-replicator]

[container-updater]

EOF

cd /etc/swift/container-server
sed -e "s/srv\/1/srv\/2/" -e "s/601/602/" -e "s/LOG_LOCAL2/LOG_LOCAL3/" 1.conf | sudo tee -a 2.conf
sed -e "s/srv\/1/srv\/3/" -e "s/601/603/" -e "s/LOG_LOCAL2/LOG_LOCAL4/" 1.conf | sudo tee -a 3.conf
sed -e "s/srv\/1/srv\/4/" -e "s/601/604/" -e "s/LOG_LOCAL2/LOG_LOCAL5/" 1.conf | sudo tee -a 4.conf

echo "[container-sync]" >> /etc/swift/container-server.conf

# Object Server config
sudo cat > /etc/swift/object-server/1.conf <<EOF
[DEFAULT]
devices = /srv/1/node
mount_check = false
bind_port = 6010
user = swift
log_facility = LOG_LOCAL2

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]
vm_test_mode = yes

[object-updater]

[object-auditor]

EOF

cd /etc/swift/object-server
sed -e "s/srv\/1/srv\/2/" -e "s/601/602/" -e "s/LOG_LOCAL2/LOG_LOCAL3/" 1.conf | sudo tee -a 2.conf
sed -e "s/srv\/1/srv\/3/" -e "s/601/603/" -e "s/LOG_LOCAL2/LOG_LOCAL4/" 1.conf | sudo tee -a 3.conf
sed -e "s/srv\/1/srv\/4/" -e "s/601/604/" -e "s/LOG_LOCAL2/LOG_LOCAL5/" 1.conf | sudo tee -a 4.conf

# Build (or rebuild) the rings
echo "This step takes a while"
sudo cp /vagrant/remakerings.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/remakerings.sh
sudo /usr/local/bin/remakerings.sh

export ENDPOINT=${ETH3_IP}
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=https://${ENDPOINT}:35357/v2.0
export OS_CACERT=/etc/ssl/certs/ca.pem
export OS_KEY=/etc/ssl/certs/cakey.pem


# Swift Proxy Address
export SWIFT_PROXY_SERVER=$ETH3_IP

# Configure the OpenStack Storage Endpoint
keystone service-create --name swift --type object-store --description 'OpenStack Storage Service'

# Service Endpoint URLs
ID=$(keystone service-list | awk '/\ swift\ / {print $2}')

PUBLIC_URL="http://$SWIFT_PROXY_SERVER:8080/v1/AUTH_\$(tenant_id)s"
ADMIN_URL="http://$SWIFT_PROXY_SERVER:8080/v1/"
INTERNAL_URL="http://$SWIFT_PROXY_SERVER:8080/v1/AUTH_\$(tenant_id)s"

keystone endpoint-create --region regionOne --service_id $ID --publicurl $PUBLIC_URL --adminurl $ADMIN_URL --internalurl $INTERNAL_URL

# Get the service tenant ID
SERVICE_TENANT_ID=$(keystone tenant-list | awk '/\ service\ / {print $2}')

# Create the swift user
keystone user-create --name swift --pass swift --tenant_id $SERVICE_TENANT_ID --email swift@localhost --enabled true

# Get the swift user id
USER_ID=$(keystone user-list | awk '/\ swift\ / {print $2}')

# Get the admin role id
ROLE_ID=$(keystone role-list | awk '/\ admin\ / {print $2}')

# Assign the swift user admin role in service tenant
keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Create .swiftrc
sudo tee /root/swiftrc >/dev/null <<EOF
export OS_USERNAME=swift
export OS_PASSWORD=swift
export OS_TENANT_NAME=service
export OS_AUTH_URL=https://${ENDPOINT}:5000/v2.0/
export OS_CACERT=/etc/ssl/certs/ca.pem
export OS_KEY=/etc/ssl/certs/cakey.pem

EOF

# Create dispersion.conf
#sudo tee /etc/swift/dispersion.conf >/dev/null <<EOF
#[dispersion]
#auth_url = https://${ENDPOINT}:5000/v2.0/
#auth_user = cookbook:admin
#auth_key = openstack
#EOF

sudo chown -L -R swift.swift /etc/swift /srv/{1..4} /run/swift

}

swift_restart(){
	# Start the Swift services
	sudo swift-init all restart
	sudo service swift-proxy restart
}

# Main
swift_install
swift_configure
swift_restart

# Copy openrc file to local instance vagrant root folder in case of loss of file share
sudo cp /vagrant/openrc /home/vagrant 
