#!/bin/bash
# heat.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh




##############################
# Chapter 9 - More OpenStack #
##############################

# Install Heat Things
sudo apt-get -y install heat-api heat-api-cfn heat-engine

MYSQL_ROOT_PASS=openstack
MYSQL_HEAT_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE heat;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$MYSQL_HEAT_PASS';"

# Configure Heat

HEAT_CONF=/etc/heat/heat.conf
cat > $HEAT_CONF <<EOF
[DEFAULT]
rabbit_host=
rabbit_port=5672
rabbit_userid=guest
rabbit_password=guest
rabbit_virtual_host=/
rabbit_ha_queues=false

use_syslog=false
log_dir=/var/log/heat

heat_watch_server_url = http://${CONTROLLER_HOST}:8003
heat_waitcondition_server_url = http://${CONTROLLER_HOST}:8000/v1/waitcondition
heat_metadata_server_url = http://${CONTROLLER_HOST}:8000

[clients]
endpoint_type = internalURL

[clients_ceilometer]
endpoint_type = internalURL

[clients_cinder]
endpoint_type = internalURL

[clients_heat]
endpoint_type = internalURL

[clients_keystone]
endpoint_type = internalURL

[clients_neutron]
endpoint_type = internalURL

[clients_nova]
endpoint_type = internalURL

[clients_swift]
endpoint_type = internalURL

[clients_trove]
endpoint_type = internalURL

[database]
backend=sqlalchemy
connection = mysql://heat:${MYSQL_HEAT_PASS}@${CONTROLLER_HOST}/heat

[keystone_authtoken]
signing_dir = /var/cache/heat
auth_uri = http://${CONTROLLER_EXTERNAL_HOST}:5000/v2.0
admin_tenant_name = service
admin_user = heat
admin_password = heat
identity_uri = https://${CONTROLLER_EXTERNAL_HOST}:35357/
insecure = True

[ec2authtoken]
auth_uri = http://${CONTROLLER_HOST}:5000/v2.0

[heat_api]
bind_port = 8004

[heat_api_cfn]
bind_port = 8000

[heat_api_cloudwatch]
bind_port = 8003
EOF

# /etc/heat/heat.conf

# Signing Dir
mkdir -p /var/cache/heat
chown heat:heat /var/cache/heat
chmod 0700 /var/cache/heat

heat-manage db_sync

keystone --insecure user-create --name=heat --pass=heat --email=heat@localhost
keystone --insecure user-role-add --user=heat --tenant=service --role=admin

keystone --insecure service-create --name=heat --type=orchestration --description="Heat Orchestration API"

ORCHESTRATION_SERVICE_ID=$(keystone service-list | awk '/\ orchestration\ / {print $2}')

keystone --insecure endpoint-create \
  --region regionOne \
  --service-id=${ORCHESTRATION_SERVICE_ID} \
  --publicurl=http://${CONTROLLER_HOST}:8004/v1/$\(tenant_id\)s \
  --internalurl=http://${CONTROLLER_HOST}:8004/v1/$\(tenant_id\)s \
  --adminurl=http://${CONTROLLER_HOST}:8004/v1/$\(tenant_id\)s

keystone --insecure service-create --name=heat-cfn --type=cloudformation --description="Heat CloudFormation API"

CLOUDFORMATION_SERVICE_ID=$(keystone service-list | awk '/\ cloudformation\ / {print $2}')

keystone --insecure endpoint-create \
  --region regionOne \
  --service-id=${CLOUDFORMATION_SERVICE_ID} \
  --publicurl=http://${CONTROLLER_HOST}:8000/v1/ \
  --internalurl=http://${CONTROLLER_HOST}:8000/v1 \
  --adminurl=http://${CONTROLLER_HOST}:8000/v1

service heat-api restart
service heat-api-cfn restart
service heat-engine restart
