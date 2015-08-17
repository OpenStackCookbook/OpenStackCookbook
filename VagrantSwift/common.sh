#!/bin/bash

# common.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 2nd Edition, October 2013
# Website: http://www.openstackcookbook.com/
# Suitable for OpenStack Grizzly

#
# Sets up common bits used in each build script.
#

export DEBIAN_FRONTEND=noninteractive

export CONTROLLER_HOST=172.16.0.200
export GLANCE_HOST=${CONTROLLER_HOST}
export MYSQL_HOST=${CONTROLLER_HOST}
export KEYSTONE_ENDPOINT=${CONTROLLER_HOST}
export SERVICE_TENANT_NAME=service
export SERVICE_PASS=openstack
export ENDPOINT=${KEYSTONE_ENDPOINT}
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0

# Setup Proxy
export APT_PROXY="172.16.0.110"
export APT_PROXY_PORT=3142
#APT_PROXY="192.168.1.1"
#APT_PROXY_PORT=3128
#
# If you have a proxy outside of your VirtualBox environment, use it
if [[ ! -z "$APT_PROXY" ]]
then
	echo 'Acquire::http { Proxy "http://'${APT_PROXY}:${APT_PROXY_PORT}'"; };' | sudo tee /etc/apt/apt.conf.d/01apt-cacher-ng-proxy
fi

sudo apt-get update
# Grizzly Goodness
sudo apt-get -y install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list
echo "deb  http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list

#sudo apt-get install python-software-properties
#sudo add-apt-repository ppa:ubuntu-cloud-archive/havana-staging


sudo apt-get update && apt-get upgrade -y

# Add host entries
echo "
172.16.0.200	controller.book controller
172.16.0.201	compute.book compute
172.16.0.202	network.book network
172.16.0.210	swift.book swift
172.16.0.221	swift1.book swift1
172.16.0.222	swift2.book swift2
172.16.0.211	iscsi.book iscsi" | tee -a /etc/hosts
