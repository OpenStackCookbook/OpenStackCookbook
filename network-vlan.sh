#!/bin/bash

# network.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)

# Source in common env vars
. /vagrant/common.sh

# The routeable IP of the node is on our eth1 interface
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

sysctl net.ipv4.ip_forward=1

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get -y install linux-headers-`uname -r`

sudo apt-get -y install vlan bridge-utils dnsmasq-base dnsmasq-utils

sudo apt-get -y install openvswitch-switch openvswitch-datapath-dkms

sudo apt-get -y install neutron-dhcp-agent   neutron-l3-agent neutron-plugin-openvswitch neutron-plugin-openvswitch-agent 

sudo /etc/init.d/openvswitch-switch start

# Edit the /etc/network/interfaces file for eth2?
sudo ifconfig eth2 0.0.0.0 up
sudo ip link set eth2 promisc on

# OpenVSwitch Configuration
#br-int will be used for VM integration
sudo ovs-vsctl add-br br-int

sudo ovs-vsctl add-br br-eth2
sudo ovs-vsctl add-port br-eth2 eth2

#sudo ovs-vsctl add-br br-ex
#sudo ovs-vsctl add-port br-ex eth3


# Configuration

# /etc/neutron/api-paste.ini
rm -f /etc/neutron/api-paste.ini
cp /vagrant/files/neutron/api-paste.ini /etc/neutron/api-paste.ini

# /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini
echo "
[DATABASE]
sql_connection=mysql://neutron:openstack@172.16.0.200/neutron
reconnect_interval = 2

[OVS]
tenant_network_type = vlan
integration_bridge = br-int
local_ip = ${MY-IP}

bridge_mappings = ph-eth2:br-eth2
network_vlan_ranges = ph-eth2:1:1000

[SECURITYGROUP]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[AGENT]
state_path = /var/run/neutron
debug = False
verbose = False
" | tee -a /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini

# /etc/neutron/dhcp_agent.ini 
#echo "root_helper = sudo neutron-rootwrap /etc/neutron/rootwrap.conf" >> /etc/neutron/dhcp_agent.ini
echo "root_helper = sudo" >> /etc/neutron/dhcp_agent.ini

echo "
Defaults !requiretty
neutron ALL=(ALL:ALL) NOPASSWD:ALL" | tee -a /etc/sudoers


# Configure Quantum
sudo sed -i "s/# rabbit_host = localhost/rabbit_host = ${CONTROLLER_HOST}/g" /etc/neutron/neutron.conf
sudo sed -i 's/# auth_strategy = keystone/auth_strategy = keystone/g' /etc/neutron/neutron.conf
sudo sed -i "s/auth_host = 127.0.0.1/auth_host = ${CONTROLLER_HOST}/g" /etc/neutron/neutron.conf
sudo sed -i 's/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/g' /etc/neutron/neutron.conf
sudo sed -i 's/admin_user = %SERVICE_USER%/admin_user = neutron/g' /etc/neutron/neutron.conf
sudo sed -i 's/admin_password = %SERVICE_PASSWORD%/admin_password = neutron/g' /etc/neutron/neutron.conf
sudo sed -i 's/^root_helper.*/root_helper = sudo/g' /etc/neutron/neutron.conf



# Restart Quantum Services
service neutron-plugin-openvswitch-agent restart



# /etc/neutron/l3_agent.ini
echo "
auth_url = http://172.16.0.200:35357/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = neutron
use_namespaces = True" | tee -a /etc/neutron/l3_agent.ini

# Metadata Agent
echo "[DEFAULT]
auth_url = http://172.16.0.200:35357/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = neutron
metadata_proxy_shared_secret = helloOpenStack
nova_metadata_ip = 172.16.0.200
nova_metadata_port = 8775
" > /etc/neutron/metadata_agent.ini

sudo service neutron-plugin-openvswitch-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-l3-agent restart
sudo service neutron-metadata-agent restart
