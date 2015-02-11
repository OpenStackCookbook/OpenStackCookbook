#!/bin/bash
. /vagrant/openrc

neutron net-create remote_network_1
neutron subnet-create --name remote_subnet_1 remote_network_1 10.2.0.0/24 --gateway 10.2.0.1
neutron router-create remote_router_1
neutron router-interface-add remote_router_1 remote_subnet_1
neutron router-gateway-set remote_router_1 ext_net

# Spin up instance on remote network
UBUNTU=$(nova image-list | awk '/\ trusty/ {print $2}')
  
REMOTE_NET_ID=$(neutron net-list | awk '/remote_network_1/ {print $2}')

nova boot --flavor 1 --image ${UBUNTU} --key_name demokey --nic net-id=${REMOTE_NET_ID} remote1

# Create VPN connections

# Create VPN in cookbook_network representing siteA

neutron vpn-ikepolicy-create ikepolicy
neutron vpn-ipsecpolicy-create ipsecpolicy

# Site 1 (cookbook)
neutron vpn-service-create --name cookbookVPN --description "Cookbook VPN Service" cookbook_router_1 cookbook_subnet_1

# --peer-cidr = remote subnet
neutron ipsec-site-connection-create --name vpnconnection1 --vpnservice-id cookbookVPN \
   --ikepolicy-id ikepolicy --ipsecpolicy-id ipsecpolicy --peer-address 192.168.100.12 \
   --peer-id 192.168.100.12 --peer-cidr 10.2.0.0/24 --psk secret

# Site 2 (remote)
neutron vpn-service-create --name remoteVPN --description "Remote VPN Service" remote_router_1 remote_subnet_1
   
neutron ipsec-site-connection-create --name vpnconnection2 --vpnservice-id remoteVPN \
   --ikepolicy-id ikepolicy --ipsecpolicy-id ipsecpolicy --peer-address 192.168.100.10 \
   --peer-id 192.168.100.10 --peer-cidr 11.200.0.0/24 --psk secret


