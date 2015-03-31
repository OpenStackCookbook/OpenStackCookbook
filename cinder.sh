#!/bin/bash

# cinder.sh

# Authors: Cody Bunch (bunchc@gmail.com)
#          Kevin Jackson (kevin@linuxservices.co.uk)

# Updated for Juno

# Source in common env vars
. /vagrant/common.sh

# Config Files
CINDER_CONF=/etc/cinder/cinder.conf

SERVICE_TENANT=service
CINDER_SERVICE_USER=cinder
CINDER_SERVICE_PASS=cinder
MYSQL_CINDER_PASS=openstack





######################
# Chapter 8 - Cinder #
######################


# Install some deps
sudo apt-get install -y linux-headers-`uname -r` build-essential python-mysqldb xfsprogs

# Keys
# Nova-Manage Hates Me
ssh-keyscan controller >> ~/.ssh/known_hosts
cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
cp /vagrant/id_rsa* ~/.ssh/

sudo scp root@controller:/etc/ssl/certs/ca.pem /etc/ssl/certs/ca.pem
sudo c_rehash /etc/ssl/certs/ca.pem

# Configure Cinder
# /etc/cinder/api-paste.ini
sudo sed -i 's/127.0.0.1/'${CONTROLLER_HOST}'/g' /etc/cinder/api-paste.ini
sudo sed -i 's/%SERVICE_TENANT_NAME%/service/g' /etc/cinder/api-paste.ini
sudo sed -i 's/%SERVICE_USER%/cinder/g' /etc/cinder/api-paste.ini
sudo sed -i 's/%SERVICE_PASSWORD%/cinder/g' /etc/cinder/api-paste.ini

## Check /vagrant/cinder.ini for "nfs" if so, do nfs things.
if grep -q nfs "/vagrant/cinder.ini"; then
	echo "[+] Installing NFS Server"
	sudo apt-get install -y nfs-kernel-server

	echo "[+] Configuring NFS Shares"
	sudo mkdir -p /exports
	sudo chown nobody:nogroup /exports
	sudo echo "
/exports/	192.168.100.0/24(rw,nohide,insecure,no_subtree_check,async)
" >> /etc/exports
	sudo service nfs-kernel-server restart
	
	echo "[+] Installing Cinder"
	sudo apt-get install -y cinder-api cinder-scheduler cinder-volume python-cinderclient
	sudo echo "cinder.book:/exports" >> /etc/cinder/nfsshares
	cat > ${CINDER_CONF} <<EOF
[DEFAULT]
rootwrap_config=/etc/cinder/rootwrap.conf
api_paste_config = /etc/cinder/api-paste.ini
volume_driver = cinder.volume.drivers.nfs.NfsDriver
nfs_shares_config = /etc/cinder/nfsshares

verbose = True
use_syslog = True
syslog_log_facility = LOG_LOCAL0

auth_strategy = keystone

rabbit_host = ${CONTROLLER_HOST}
rabbit_port = 5672
state_path = /var/lib/cinder/

# Default glance port (integer value)
glance_port=9292
glance_api_servers=${CONTROLLER_HOST}:${glance_port}
glance_api_version=1
glance_num_retries=0
glance_api_insecure=True

scheduler_topic=cinder-scheduler
volume-topic=cinder-volume
backup-topic=cinder-backup

scheduler_manager=cinder.scheduler.manager.SchedulerManager

[database]
backend=sqlalchemy
connection = mysql://cinder:${MYSQL_CINDER_PASS}@${CONTROLLER_HOST}/cinder

[keystone_authtoken]
auth_host = ${KEYSTONE_ADMIN_ENDPOINT}
auth_port = 35357
auth_protocol = https
auth_uri = https://${KEYSTONE_ENDPOINT}:5000/
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${CINDER_SERVICE_USER}
admin_password = ${CINDER_SERVICE_PASS}
insecure = True

EOF

else
	echo "[+} ISCSI Instead"

	# Install Cinder Things
	sudo apt-get install -y tgt open-iscsi

	# Restart services
	sudo service open-iscsi start

	dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=20G

	losetup /dev/loop2 cinder-volumes
	pvcreate /dev/loop2
	vgcreate cinder-volumes /dev/loop2
	glance_port=9292

	echo "[+] Installing Cinder"
	sudo apt-get install -y cinder-api cinder-scheduler cinder-volume python-cinderclient
	cat > ${CINDER_CONF} <<EOF
[DEFAULT]
rootwrap_config=/etc/cinder/rootwrap.conf
api_paste_config = /etc/cinder/api-paste.ini
iscsi_helper=tgtadm
iscsi_ip_address=172.16.0.211
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
use_syslog = True
syslog_log_facility = LOG_LOCAL0

auth_strategy = keystone

rabbit_host = ${CONTROLLER_HOST}
rabbit_port = 5672
state_path = /var/lib/cinder/

# Default glance port (integer value)
glance_port=9292
glance_api_servers=${CONTROLLER_HOST}:${glance_port}
glance_api_version=1
glance_num_retries=0
glance_api_insecure=True

scheduler_topic=cinder-scheduler
volume-topic=cinder-volume
backup-topic=cinder-backup

scheduler_manager=cinder.scheduler.manager.SchedulerManager

[database]
backend=sqlalchemy
connection = mysql://cinder:${MYSQL_CINDER_PASS}@${CONTROLLER_HOST}/cinder

[keystone_authtoken]
auth_host = ${KEYSTONE_ADMIN_ENDPOINT}
auth_port = 35357
auth_protocol = https
auth_uri = https://${KEYSTONE_ENDPOINT}:5000/
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${CINDER_SERVICE_USER}
admin_password = ${CINDER_SERVICE_PASS}
insecure = True

EOF

fi

sleep 5

# Sync DB
cinder-manage db sync

# Restart services
cd /etc/init/; for c in $( ls cinder-* | cut -d '.' -f1) ; do sudo stop $c; start $c; done

cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

# Logging
sudo stop rsyslog
sudo cp /vagrant/rsyslog.conf /etc/rsyslog.conf
sudo echo "*.*         @@controller:5140" >> /etc/rsyslog.d/50-default.conf
sudo service rsyslog restart

# Copy openrc file to local instance vagrant root folder in case of loss of file share
sudo cp /vagrant/openrc /home/vagrant 
