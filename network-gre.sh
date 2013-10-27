#!/bin/bash

# network.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 2nd Edition, October 2013
# Website: http://www.openstackcookbook.com/
# Suitable for OpenStack Grizzly

# Source in common env vars
. /vagrant/common.sh

# The routeable IP of the node is on our eth1 interface
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH3_IP=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl net.ipv4.ip_forward=1

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install linux-headers-`uname -r`
sudo apt-get -y install vlan bridge-utils dnsmasq-base dnsmasq-utils
sudo apt-get -y install openvswitch-switch openvswitch-datapath-dkms
sudo apt-get -y install neutron-dhcp-agent neutron-l3-agent neutron-plugin-openvswitch neutron-plugin-openvswitch-agent 
sudo /etc/init.d/openvswitch-switch start

# Edit the /etc/network/interfaces file for eth2?
sudo ifconfig eth2 0.0.0.0 up
sudo ip link set eth2 promisc on

# OpenVSwitch Configuration
#br-int will be used for VM integration
sudo ovs-vsctl add-br br-int

sudo ovs-vsctl add-br br-eth2
sudo ovs-vsctl add-port br-eth2 eth2

sudo ovs-vsctl add-br br-ex
sudo ovs-vsctl add-port br-ex eth3

# Edit the /etc/network/interfaces file for eth3?
sudo ifconfig eth3 0.0.0.0 up
sudo ip link set eth3 promisc on
# Assign IP to br-ex so it is accessible
sudo ifconfig br-ex $ETH3_IP netmask 255.255.255.0


# Configuration

# /etc/neutron/api-paste.ini
rm -f /etc/neutron/api-paste.ini
cp /vagrant/files/neutron/api-paste.ini /etc/neutron/api-paste.ini

echo "
[DATABASE]
sql_connection=mysql://neutron:openstack@${CONTROLLER_HOST}/neutron
[OVS]
tenant_network_type=gre
tunnel_id_ranges=1:1000
integration_bridge=br-int
tunnel_bridge=br-tun
local_ip=${MY_IP}
enable_tunneling=True
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf
[SECURITYGROUP]
# Firewall driver for realizing neutron security group function
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
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
auth_url = http://${KEYSTONE_ENDPOINT}:35357/v2.0
auth_region = RegionOne
admin_tenant_name = service
admin_user = neutron
admin_password = neutron
metadata_ip = ${CONTROLLER_HOST}
metadata_port = 8775
use_namespaces = True" | tee -a /etc/neutron/l3_agent.ini

#
sed -i 's/.*OVSInterfaceDriver.*/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/' /etc/neutron/l3_agent.ini 

# Metadata Agent
echo "[DEFAULT]
auth_url = http://172.16.0.200:35357/v2.0
auth_region = RegionOne
admin_tenant_name = service
admin_user = neutron
admin_password = neutron
metadata_proxy_shared_secret = foo
nova_metadata_ip = ${CONTROLLER_HOST}
nova_metadata_port = 8775
" > /etc/neutron/metadata_agent.ini

sudo service neutron-plugin-openvswitch-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-l3-agent restart
sudo service neutron-metadata-agent restart
