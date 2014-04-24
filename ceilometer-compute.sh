#!/bin/bash

# ceilometer-compute.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh

# Install Ceilometer Things
sudo apt-get -y install ceilometer-agent-compute

# Configure Ceilometer
sudo sed -i "s/^.*metering_secret.*/metering_secret = ${MONGO_KEY} /g" /etc/ceilometer/ceilometer.conf

# Configure /etc/nova/nova.conf
echo "# Ceilometer
instance_usage_audit=True
instance_usage_audit_period=hour
notify_on_state_change=vm_and_task_state
notification_driver=nova.openstack.common.notifier.rpc_notifier" | sudo tee -a /etc/nova/nova.conf

cd /etc/init
ls nova* | cut -d '.' -f1 | while read S; do stop $S; start $S; done
service ceilometer-agent-compute restart
