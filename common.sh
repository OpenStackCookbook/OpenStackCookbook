#!/bin/bash

# common.sh
#
# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)
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
sudo apt-get update && apt-get upgrade -y
