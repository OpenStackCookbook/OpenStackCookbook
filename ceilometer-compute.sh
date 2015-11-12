#!/bin/bash

# ceilometer-compute.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh




##############################
# Chapter 9 - More OpenStack #
##############################

# Install Ceilometer Things
sudo apt-get -y install ceilometer-agent-compute

# Configure /etc/nova/nova.conf
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
identity_uri = https://192.168.100.200:35357
admin_tenant_name = service
admin_user = ceilometer
admin_password = ceilometer
revocation_cache_time = 10
insecure = True

[service_credentials]
os_auth_url = https://192.168.100.200:5000/v2.0
os_username = ceilometer
os_tenant_name = service
os_password = ceilometer
insecure = True
 
[publisher_rpc]
metering_secret = foobar 
EOF

echo "# Ceilometer
instance_usage_audit=True
instance_usage_audit_period=hour
notify_on_state_change=vm_and_task_state
notification_driver=nova.openstack.common.notifier.rpc_notifier" | sudo tee -a /etc/nova/nova.conf

cd /etc/init
ls nova* | cut -d '.' -f1 | while read S; do stop $S; start $S; done
service ceilometer-agent-compute restart
