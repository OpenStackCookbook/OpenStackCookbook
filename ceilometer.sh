#!/bin/bash

# ceilometer.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh

# Install Ceilometer Things
sudo apt-get -y install ceilometer-api ceilometer-collector ceilometer-agent-central python-ceilometerclient mongodb

sudo service mongodb restart

# Configure Ceilometer
# /etc/ceilometer/ceilometer.conf
sudo sed -i "s/^#backend.*/backend=mongodb/g" /etc/ceilometer/ceilometer.conf
sudo sed -i "s,^connection.*,connection = mongodb://ceilometer:openstack@localhost:27017/ceilometer,g" /etc/ceilometer/ceilometer.conf

sudo sed -i "s/^.*metering_secret.*/metering_secret = ${MONGO_KEY} /g" /etc/ceilometer/ceilometer.conf

sudo sed -i "s/^\[keystone_authtoken\]/# [keystone_authtoken]/g" /etc/ceilometer/ceilometer.conf

echo "
[keystone_authtoken]
auth_host = ${CONTROLLER_HOST}
auth_port = 35357
auth_protocol = http
auth_uri = https://${CONTROLLER_HOST}:35357/
admin_tenant_name = service
admin_user = ceilometer
admin_password = ceilometer" | tee -a /etc/ceilometer/ceilometer.conf

keystone --insecure user-create --name=ceilometer --pass=ceilometer --email=heat@localhost
keystone --insecure user-role-add --user=ceilometer --tenant=service --role=admin

keystone --insecure service-create --name=ceilometer --type=metering --description="Ceilometer Metering Service"

METERING_SERVICE_ID=$(keystone service-list | awk '/\ metering\ / {print $2}')

keystone --insecure endpoint-create \
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

service mongodb restart

sleep 2

service ceilometer-agent-central restart
sleep 1
service ceilometer-collector restart
sleep 1
service ceilometer-api restart
