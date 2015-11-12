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

export DEBIAN_FRONTEND=noninteractive

ETH1_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH2_IP=$(ifconfig eth2 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH3_IP=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')


# Talk to a proxy server
# echo 'Acquire::http { Proxy "http://192.168.1.20:3142"; };' | sudo tee /etc/apt/apt.conf.d/01apt-cacher-ng-proxy


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
192.168.100.209	swift-proxy.book swift-proxy
192.168.100.221 swift-01.book swift-01
192.168.100.222 swift-02.book swift-02
192.168.100.223 swift-03.book swift-03
192.168.100.224 swift-04.book swift-04
192.168.100.225 swift-05.book swift-05" | sudo tee -a /etc/hosts
fi

# Aliases for insecure SSL
# alias nova='nova --insecure'
# alias keystone='keystone --insecure'
# alias neutron='neutron --insecure'
# alias glance='glance --insecure'
# alias cinder='cinder --insecure'
