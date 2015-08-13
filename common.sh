#!/bin/bash

#  common.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)
#          Egle Sigler (ushnishtha@hotmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 3rd Edition, 2014
# Website: http://www.openstackcookbook.com/
# Scripts updated for Juno!

#
# Sets up common bits used in each build script.
#

# Useful if you have a cache on your network. Adjust to suit.
# echo "Acquire::http { Proxy \"http://192.168.1.20:3142\"; };" > /etc/apt/apt.conf.d/01squid

export DEBIAN_FRONTEND=noninteractive
echo "set grub-pc/install_devices /dev/sda" | debconf-communicate

ETH1_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH2_IP=$(ifconfig eth2 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH3_IP=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

#export CONTROLLER_HOST=172.16.0.200
#Dynamically determine first three octets if user specifies alternative IP ranges.  Fourth octet still hardcoded
export CONTROLLER_HOST=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' | sed 's/\.[0-9]*$/.200/')
export GLANCE_HOST=${CONTROLLER_HOST}
export MYSQL_HOST=${CONTROLLER_HOST}
export KEYSTONE_ADMIN_ENDPOINT=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' | sed 's/\.[0-9]*$/.200/')
export KEYSTONE_ENDPOINT=${KEYSTONE_ADMIN_ENDPOINT}
export CONTROLLER_EXTERNAL_HOST=${KEYSTONE_ADMIN_ENDPOINT}
export MYSQL_NEUTRON_PASS=openstack
export SERVICE_TENANT_NAME=service
export SERVICE_PASS=openstack
export ENDPOINT=${KEYSTONE_ADMIN_ENDPOINT}
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=https://${KEYSTONE_ADMIN_ENDPOINT}:35357/v2.0
export MONGO_KEY=MongoFoo
export OS_CACERT=/vagrant/ca.pem
export OS_KEY=/vagrant/cakey.pem

sudo apt-get install -y software-properties-common ubuntu-cloud-keyring
sudo add-apt-repository -y cloud-archive:juno
sudo apt-get update && sudo apt-get upgrade -y

if [[ "$(egrep CookbookHosts /etc/hosts | awk '{print $2}')" -eq "" ]]
then
	# Add host entries
	echo "
# CookbookHosts
192.168.100.200	controller.book controller
192.168.100.201	network.book network
192.168.100.202	compute-01.book compute-01
192.168.100.203	compute-02.book compute-02
192.168.100.210	swift.book swift
192.168.100.212	swift2.book swift2
192.168.100.211	cinder.book cinder" | sudo tee -a /etc/hosts
fi

# Aliases for insecure SSL
# alias nova='nova --insecure'
# alias keystone='keystone --insecure'
# alias neutron='neutron --insecure'
# alias glance='glance --insecure'
# alias cinder='cinder --insecure'
