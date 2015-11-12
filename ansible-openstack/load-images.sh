#!/bin/bash

# Grab openrc from utility container
UTILITY=$(awk '/controller-01_utility/ {print $2}' /etc/hosts)
scp root@$UTILITY:openrc .
chmod 0600 openrc
. openrc

glance image-create --name "trusty-image" --disk-format=qcow2 --container-format=bare --location http://nas2/trusty-server-cloudimg-amd64-disk1.img

glance image-create --name "windows-image" --disk-format=qcow2 --container-format=bare --location http://nas2/win2k-image.qcow2
