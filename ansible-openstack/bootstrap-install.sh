#!/bin/bash

# This shells into logging and tells logging to execute /vagrant/install-openstack.sh
ssh -i /vagrant/id_rsa root@logging "/vagrant/install-openstack.sh"
