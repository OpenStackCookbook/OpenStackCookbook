#!/bin/bash

# SECURITY ERRORS
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40976EAF437D05B5

#mkdir -p /etc/apt/apt.conf.d
#echo "Acquire::http { Proxy \"http://apt-cacher.lab.openstackcookbook.com:3142\"; };" > /etc/apt/apt.conf.d/01squid

sudo apt-key update
sudo apt-get update
# sudo apt-get -y upgrade

sudo apt-get -y install bridge-utils debootstrap ifenslave ifenslave-2.6 lsof lvm2 tcpdump vlan aptitude build-essential git ntp ntpdate python-dev libyaml-dev libpython2.7-dev
