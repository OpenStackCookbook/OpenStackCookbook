#!/bin/bash

# cinder.sh

# Authors: Cody Bunch (bunchc@gmail.com)
#          Kevin Jackson (kevin@linuxservices.co.uk)

# Updated for Icehouse

# Source in common env vars
. /vagrant/common.sh

# Install some deps
sudo apt-get install -y linux-headers-`uname -r` build-essential python-mysqldb xfsprogs

# Install Cinder Things
sudo apt-get install -y cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt

# Restart services
sudo service open-iscsi start


# Config Files
CINDER_CONF=/etc/cinder/cinder.conf

SERVICE_TENANT=service
CINDER_SERVICE_USER=cinder
CINDER_SERVICE_PASS=cinder
MYSQL_CINDER_PASS=openstack

# Configure Cinder
cp ${CINDER_CONF}{,.bak}

cat > /etc/cinder/cinder.conf <<EOF
[DEFAULT]
rootwrap_config=/etc/cinder/rootwrap.conf
api_paste_config = /etc/cinder/api-paste.ini
iscsi_helper=tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
use_syslog = True
syslog_log_facility = LOG_LOCAL0

auth_strategy = keystone

rabbit_host = ${CONTROLLER_HOST}
rabbit_port = 5672
state_path = /var/lib/cinder/

[database]
backend=sqlalchemy
connection = mysql://cinder:${MYSQL_CINDER_PASS}@${CONTROLLER_HOST}/cinder

[keystone_authtoken]
service_protocol = http
service_host = ${CONTROLLER_HOST}
service_port = 5000
auth_host = ${CONTROLLER_HOST}
auth_port = 35357
auth_protocol = http
auth_uri = http://${CONTROLLER_HOST}:5000/
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${CINDER_SERVICE_USER}
admin_password = ${CINDER_SERVICE_PASS}

EOF

# Sync DB
cinder-manage db sync

# Setup loopback FS for iscsi
dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=5G

losetup /dev/loop2 cinder-volumes
pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2

# Restart services
cd /etc/init/; for c in $( ls cinder-* | cut -d '.' -f1) ; do sudo stop $c; start $c; done

cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

# Logging
sudo stop rsyslog
sudo cp /vagrant/rsyslog.conf /etc/rsyslog.conf
sudo echo "*.*         @@controller:5140" >> /etc/rsyslog.d/50-default.conf
sudo service rsyslog restart