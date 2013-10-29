#!/bin/bash

# heat.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh

# Install Heat Things
sudo apt-get -y install heat-api heat-api-cfn heat-engine

MYSQL_ROOT_PASS=openstack
MYSQL_HEAT_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE heat;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "SET PASSWORD FOR 'heat'@'%' = PASSWORD('$MYSQL_HEAT_PASS');"

# Configure Heat
# /etc/heat/heat.conf
sudo sed -i 's,^connection.*,connection = mysql://heat:${MYSQL_HEAT_PASS}@${MYSQL_HOST}/heat,g' /etc/heat/heat.conf
sudo sed -i 's/^verbose.*/verbose = True/g' /etc/heat/heat.conf
sudo sed -i 's/^log_dir.*,log_dir = /var/log/heat,g' /etc/heat/heat.conf

sudo sed -i 's/127.0.0.1/'${CONTROLLER_HOST}'/g' /etc/heat/api-paste.ini
sudo sed -i 's/%SERVICE_TENANT_NAME%/service/g' /etc/heat/api-paste.ini
sudo sed -i 's/%SERVICE_USER%/heat/g' /etc/heat/api-paste.ini
sudo sed -i 's/%SERVICE_PASSWORD%/heat/g' /etc/heat/api-paste.ini


heat-manage db_sync

keystone user-create --name=heat --pass=heat --email=heat@localhost
keystone user-role-add --user=heat --tenant=service --role=admin

keystone service-create --name=heat --type=orchestration \
  --description="Heat Orchestration API"

keystone endpoint-create \
  --service-id=the_service_id_above \
  --publicurl=http://${CONTROLLER_HOST}:8004/v1/%\(tenant_id\)s \
  --internalurl=http://${CONTROLLER_HOST}:8004/v1/%\(tenant_id\)s \
  --adminurl=http://${CONTROLLER_HOST}:8004/v1/%\(tenant_id\)s

keystone service-create --name=heat-cfn --type=cloudformation \
  --description="Heat CloudFormation API"

keystone endpoint-create \
  --service-id=the_service_id_above \
  --publicurl=http://${CONTROLLER_HOST}:8000/v1 \
  --internalurl=http://${CONTROLLER_HOST}:8000/v1 \
  --adminurl=http://${CONTROLLER_HOST}:8000/v1

service heat-api restart
service heat-api-cfn restart
service heat-engine restart
