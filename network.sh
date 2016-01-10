#!/bin/bash

# network.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)
#          Egle Sigler (ushnishtha@hotmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 3rd Edition
# Website: http://www.openstackcookbook.com/
# Suitable for OpenStack Juno

# Source in common env vars
. /vagrant/common.sh
# Keys
# Nova-Manage Hates Me
ssh-keyscan controller >> ~/.ssh/known_hosts
cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
cp /vagrant/id_rsa* ~/.ssh/

# The routeable IP of the node is on our eth1 interface
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH2_IP=$(ifconfig eth2 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH3_IP=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')


##########################
# Chapter 3 - Networking #
##########################

echo "net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0" | tee -a /etc/sysctl.conf
sysctl -p

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install linux-headers-`uname -r`
sudo scp root@controller:/etc/ssl/certs/ca.pem /etc/ssl/certs/ca.pem
sudo c_rehash /etc/ssl/certs/ca.pem
sudo apt-get -y install vlan bridge-utils dnsmasq-base dnsmasq-utils
sudo apt-get -y install neutron-plugin-ml2 neutron-plugin-openvswitch-agent openvswitch-switch neutron-l3-agent neutron-dhcp-agent ipset python-mysqldb neutron-lbaas-agent haproxy

sudo /etc/init.d/openvswitch-switch start


# OpenVSwitch Configuration
#br-int will be used for VM integration
#sudo ovs-vsctl add-br br-int

# Neutron Tenant Tunnel Network
sudo ovs-vsctl add-br br-eth2
sudo ovs-vsctl add-port br-eth2 eth2

# In reality you would edit the /etc/network/interfaces file for eth3?
sudo ifconfig eth2 0.0.0.0 up
sudo ip link set eth2 promisc on
# Assign IP to br-eth2 so it is accessible
sudo ifconfig br-eth2 $ETH2_IP netmask 255.255.255.0

# Neutron External Router Network
sudo ovs-vsctl add-br br-ex
sudo ovs-vsctl add-port br-ex eth3

# In reality you would edit the /etc/network/interfaces file for eth3
sudo ifconfig eth3 0.0.0.0 up
sudo ip link set eth3 promisc on
# Assign IP to br-ex so it is accessible
sudo ifconfig br-ex $ETH3_IP netmask 255.255.255.0


# Configuration

# Config Files
NEUTRON_CONF=/etc/neutron/neutron.conf
NEUTRON_PLUGIN_ML2_CONF_INI=/etc/neutron/plugins/ml2/ml2_conf.ini
NEUTRON_L3_AGENT_INI=/etc/neutron/l3_agent.ini
NEUTRON_DHCP_AGENT_INI=/etc/neutron/dhcp_agent.ini
NEUTRON_DNSMASQ_CONF=/etc/neutron/dnsmasq-neutron.conf
NEUTRON_METADATA_AGENT_INI=/etc/neutron/metadata_agent.ini
NEUTRON_FWAAS_DRIVER_INI=/etc/neutron/fwaas_driver.ini
NEUTRON_VPNAAS_AGENT_INI=/etc/neutron/vpn_agent.ini
NEUTRON_LBAAS_AGENT_INI=/etc/neutron/lbaas_agent.ini

SERVICE_TENANT=service
NEUTRON_SERVICE_USER=neutron
NEUTRON_SERVICE_PASS=neutron

# Configure Neutron
cat > ${NEUTRON_CONF} << EOF
[DEFAULT]
verbose = True
debug = False
state_path = /var/lib/neutron
lock_path = \$state_path/lock
log_dir = /var/log/neutron
use_syslog = True
syslog_log_facility = LOG_LOCAL0

bind_host = 0.0.0.0
bind_port = 9696

# Plugin
core_plugin = ml2
# service_plugins: router firewall lbaas vpn
#service_plugins = router,firewall
service_plugins = router, lbaas
allow_overlapping_ips = True
#router_distributed = True

# auth
auth_strategy = keystone

# RPC configuration options. Defined in rpc __init__
# The messaging module to use, defaults to kombu.
rpc_backend = neutron.openstack.common.rpc.impl_kombu

rabbit_host = ${CONTROLLER_HOST}
rabbit_password = guest
rabbit_port = 5672
rabbit_userid = guest
rabbit_virtual_host = /
rabbit_ha_queues = false

# ============ Notification System Options =====================
notification_driver = neutron.openstack.common.notifier.rpc_notifier

[agent]
root_helper = sudo

[keystone_authtoken]
auth_uri = https://${KEYSTONE_ADMIN_ENDPOINT}:35357/v2.0/
identity_uri = https://${KEYSTONE_ADMIN_ENDPOINT}:5000
admin_tenant_name = ${SERVICE_TENANT}
admin_user = ${NEUTRON_SERVICE_USER}
admin_password = ${NEUTRON_SERVICE_PASS}
#signing_dir = \$state_path/keystone-signing
insecure = True

[database]
connection = mysql://neutron:${MYSQL_NEUTRON_PASS}@${CONTROLLER_HOST}/neutron

[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
#service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default
#service_provider=FIREWALL:Iptables:neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver:default

EOF

cat > ${NEUTRON_L3_AGENT_INI} << EOF
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
#agent_mode = dvr_snat
external_network_bridge = br-ex
verbose = True
EOF

cat > ${NEUTRON_DHCP_AGENT_INI} << EOF
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True
dnsmasq_config_file=${NEUTRON_DNSMASQ_CONF}
EOF

cat > ${NEUTRON_DNSMASQ_CONF} << EOF
# To allow tunneling bytes to be appended
dhcp-option-force=26,1400
EOF

cat > ${NEUTRON_METADATA_AGENT_INI} << EOF
[DEFAULT]
auth_url = https://${KEYSTONE_ENDPOINT}:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = ${NEUTRON_SERVICE_USER}
admin_password = ${NEUTRON_SERVICE_PASS}
nova_metadata_ip = ${CONTROLLER_HOST}
metadata_proxy_shared_secret = foo
auth_insecure = True
EOF

cat > ${NEUTRON_PLUGIN_ML2_CONF_INI} << EOF
[ml2]
type_drivers = gre,vxlan,vlan,flat
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population

[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]
#vxlan_group =
vni_ranges = 1:1000

[ml2_type_flat]
flat_networks = eth3

#[vxlan]
#enable_vxlan = True
#vxlan_group =
#local_ip = ${ETH2_IP}
#l2_population = True

[agent]
tunnel_types = vxlan
l2_population = True
#enable_distributed_routing = True
#arp_responder = True

[ovs]
local_ip = ${ETH2_IP}
tunnel_type = vxlan
enable_tunneling = True
l2_population = True
#enable_distributed_routing = True
tunnel_bridge = br-tun

[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = True
EOF

cat > ${NEUTRON_FWAAS_DRIVER_INI} <<EOF
[fwaas]
driver = neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver
enabled = True
EOF

cat > ${NEUTRON_VPNAAS_AGENT_INI} <<EOF
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver

[vpnagent]
vpn_device_driver=neutron.services.vpn.device_drivers.ipsec.OpenSwanDriver

[ipsec]
ipsec_status_check_interval=60
EOF

cat > ${NEUTRON_LBAAS_AGENT_INI} <<EOF
[DEFAULT]
debug = False
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
device_driver = neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver

[haproxy]
loadbalancer_state_path = \$state_path/lbaas
user_group = nogroup
EOF

echo "
Defaults !requiretty
neutron ALL=(ALL:ALL) NOPASSWD:ALL" | tee -a /etc/sudoers


# Restart Neutron Services
sudo service neutron-plugin-openvswitch-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-l3-agent stop # DVR SO DONT RUN
sudo service neutron-l3-agent start # NON-DVR
sudo start neutron-lbaas-agent stop
sudo start neutron-lbaas-agent start
sudo service neutron-metadata-agent restart
#sudo service neutron-vpn-agent stop
#sudo service neutron-vpn-agent start

cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

# Logging
sudo stop rsyslog
sudo cp /vagrant/rsyslog.conf /etc/rsyslog.conf
sudo echo "*.*         @@controller:5140" >> /etc/rsyslog.d/50-default.conf
sudo service rsyslog restart

# Copy openrc file to local instance vagrant root folder in case of loss of file share
sudo cp /vagrant/openrc /home/vagrant 
