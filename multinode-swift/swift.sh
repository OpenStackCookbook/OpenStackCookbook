# swift.sh
# This preps and creates the Swift storage nodes

source /vagrant/common.sh

swift_storage_services_install() {
	# Install some packages:
	sudo apt-get -y install swift-account swift-container swift-object memcached xfsprogs curl python-webob
	sudo service ntp restart

	# Create signing directory & Set owner to swift
	mkdir /var/swift-signing
	chown -R swift /var/swift-signing

	# Create cache directory & set owner to swift
	mkdir -p /var/cache/swift
	chown -R swift:swift /var/cache/swift
	
}

swift_disk_prep(){

  sudo parted -s /dev/sdb mklabel msdos
  NUM_CYLINDERS=$(sudo parted /dev/sdb unit cyl print | awk '/Disk.*cyl/ {print $3}')
  sudo parted -s /dev/sdb mkpart primary 0cyl $NUM_CYLINDERS
  sudo partprobe
  sudo mkfs.xfs -f -i size=1024 /dev/sdb1
  sudo mkdir -p /srv/node/sdb1
  echo "/dev/sdb1 /srv/node/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" | sudo tee -a /etc/fstab
  sudo mount /srv/node/sdb1
  chown -R swift:swift /srv/node
}

swift_storage_services_configure() {

	# Setup rsync
sudo cat > /etc/rsyncd.conf <<EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = ${ETH1_IP}

[account]
max connections = 25
path = /srv/node/
read only = false
lock file = /var/lock/account.lock

[container]
max connections = 25
path = /srv/node/
read only = false
lock file = /var/lock/container.lock

[object]
max connections = 25
path = /srv/node/
read only = false
lock file = /var/lock/object.lock

EOF

sudo sed -i 's/=false/=true/' /etc/default/rsync
sudo service rsync start

# Setup /etc/swift/swift.conf
sudo cp /vagrant/swift.conf /etc/swift

# Setup Account Server
sudo cat > /etc/swift/account-server.conf <<EOF
[DEFAULT]
devices = /srv/node
mount_check = false
bind_port = 6002
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

# Container Server config
sudo cat > /etc/swift/container-server.conf <<EOF
[DEFAULT]
devices = /srv/node
mount_check = false
bind_port = 6001
user = swift
log_facility = LOG_LOCAL2
#allowed_sync_hosts = swift1,swift2

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[account-replicator]
vm_test_mode = yes

[account-updater]

[account-auditor]

[account-sync]

#[container-sync]
# Will sync, at most, each container once per interval
#interval = 20
# Maximum amount of time to spend syncing each container per pass
#container_time = 60

[container-auditor]

[container-replicator]

[container-updater]

EOF

# Object Server config
sudo cat > /etc/swift/object-server.conf <<EOF
[DEFAULT]
devices = /srv/node
mount_check = false
bind_port = 6000
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

sudo chown -L -R swift.swift /etc/swift 

}

copy_ssh_keys() {
  # The controller creates a new ssh keypair on boot
  sudo mkdir --mode=0700 -p /root/.ssh/
  sudo cp /vagrant/id_rsa /root/.ssh/
  sudo cp /vagrant/id_rsa.pub /root/.ssh/
  cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
}

# Main
swift_storage_services_install
swift_disk_prep
swift_storage_services_configure
copy_ssh_keys
