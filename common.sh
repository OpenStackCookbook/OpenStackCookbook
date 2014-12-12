#!/bin/bash

#  common.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 2nd Edition, October 2013
# Website: http://www.openstackcookbook.com/
# Scripts updated for Icehouse!

#
# Sets up common bits used in each build script.
#

export DEBIAN_FRONTEND=noninteractive

#export CONTROLLER_HOST=172.16.0.200
#Dynamically determine first three octets if user specifies alternative IP ranges.  Fourth octet still hardcoded
export CONTROLLER_HOST=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' | sed 's/\.[0-9]*$/.200/')
export GLANCE_HOST=${CONTROLLER_HOST}
export MYSQL_HOST=${CONTROLLER_HOST}
export KEYSTONE_ENDPOINT=${CONTROLLER_HOST}
export MYSQL_NEUTRON_PASS=openstack
export SERVICE_TENANT_NAME=service
export SERVICE_PASS=openstack
export ENDPOINT=${KEYSTONE_ENDPOINT}
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0
export MONGO_KEY=MongoFoo

sudo apt-get install -y software-properties-common ubuntu-cloud-keyring
sudo add-apt-repository -y cloud-archive:juno
sudo apt-get update && sudo apt-get upgrade -y

if [[ "$(egrep CookbookHosts /etc/hosts | awk '{print $2}')" -eq "" ]]
then
	# Add host entries
	echo "
# CookbookHosts
172.16.0.200	controller.book controller
172.16.0.201	network.book network
172.16.0.202	compute.book compute
172.16.0.203	compute2.book compute2
172.16.0.210	swift.book swift
172.16.0.211	cinder.book cinder" | sudo tee -a /etc/hosts
fi
