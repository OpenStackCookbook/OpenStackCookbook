#!/bin/bash

# ceilometer.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh


CEILOMETER_SERVICE_USER=ceilometer
CEILOMETER_SERVICE_PASS=ceilometer


##############################
# Chapter 9 - More OpenStack #
##############################


# Install Ceilometer Things
sudo apt-get -y install ceilometer-api ceilometer-collector ceilometer-agent-central python-ceilometerclient mongodb python-pymongo python-bson

sudo service mongodb restart

# Configure Ceilometer
# /etc/ceilometer/ceilometer.conf
#sudo sed -i "s/^#backend.*/backend=mongodb/g" /etc/ceilometer/ceilometer.conf
#sudo sed -i "s,^connection.*,connection = mongodb://ceilometer:openstack@localhost:27017/ceilometer,g" /etc/ceilometer/ceilometer.conf
#
#sudo sed -i "s/^.*metering_secret.*/metering_secret = ${MONGO_KEY} /g" /etc/ceilometer/ceilometer.conf
#
#sudo sed -i "s/^\[keystone_authtoken\]/# [keystone_authtoken]/g" /etc/ceilometer/ceilometer.conf
#
#echo "
#[keystone_authtoken]
#identity_uri = http://${ETH3_IP}:35357
#admin_tenant_name = service
#admin_user = ceilometer
#admin_password = ceilometer
#revocation_cache_time = 10
#insecure = True
#" | tee -a /etc/ceilometer/ceilometer.conf

cat > /etc/ceilometer/ceilometer.conf <<EOF
[DEFAULT]
policy_file = /etc/ceilometer/policy.json
verbose = true
debug = true
insecure = true
 
##### AMQP #####
notification_topics = notifications,glance_notifications
 
rabbit_host=172.16.0.200
rabbit_port=5672
rabbit_userid=guest
rabbit_password=guest
rabbit_virtual_host=/
rabbit_ha_queues=false
 
[database]
connection=mongodb://ceilometer:openstack@172.16.0.200:27017/ceilometer
 
[api]
host = 172.16.0.200
port = 8777
 
[keystone_authtoken]
auth_uri = http://${KEYSTONE_ADMIN_ENDPOINT}:35357/v2.0/
identity_uri = http://${KEYSTONE_ADMIN_ENDPOINT}:5000
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${CEILOMETER_SERVICE_USER}
admin_password = ${CEILOMETER_SERVICE_PASS}
#signing_dir = \$state_path/keystone-signing
insecure = True

[service_credentials]
os_auth_url = http://192.168.100.200:5000/v2.0
os_username = ceilometer
os_tenant_name = service
os_password = ceilometer
insecure = True

EOF

keystone user-create --name=ceilometer --pass=ceilometer --email=ceilometer@localhost
keystone user-role-add --user=ceilometer --tenant=service --role=admin

keystone service-create --name=ceilometer --type=metering --description="Ceilometer Metering Service"

METERING_SERVICE_ID=$(keystone service-list | awk '/\ metering\ / {print $2}')

keystone endpoint-create \
  --region regionOne \
  --service-id=${METERING_SERVICE_ID} \
  --publicurl=http://${CONTROLLER_HOST}:8777 \
  --internalurl=http://${CONTROLLER_HOST}:8777 \
  --adminurl=http://${CONTROLLER_HOST}:8777

# Ceilometer uses MongoDB

echo 'db.addUser( { user: "ceilometer",
              pwd: "openstack",
              roles: [ "readWrite", "dbAdmin" ]
            } );' | tee -a /tmp/ceilometer.js

mongo ceilometer /tmp/ceilometer.js

sed -i 's/^bind_ip.*/bind_ip = 172.16.0.200/g' /etc/mongodb.conf

service mongodb restart

sleep 2

service ceilometer-agent-central restart
sleep 1
service ceilometer-collector restart
sleep 1
service ceilometer-api restart
