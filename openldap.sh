#!/bin/bash

# openldap.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 2nd Edition, October 2013
# Website: http://www.openstackcookbook.com/
# Scripts updated for Juno

# Source in common env vars
. /vagrant/common.sh

# The routeable IP of the node is on our eth1 interface
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

#export LANG=C

# Set some configuration variables
echo -e " \
slapd	slapd/internal/adminpw	password	openstack
slapd	slapd/internal/generated_adminpw	password	openstack
slapd	slapd/password2	password	openstack
slapd	slapd/password1	password	openstack
" | sudo debconf-set-selections

# Install OpenLDAP
sudo apt-get install -y slapd ldap-utils

sudo echo "
attributetype ( 1.2.840.113556.1.4.8 NAME 'userAccountControl'
    SYNTAX '1.3.6.1.4.1.1466.115.121.1.27' )

objectclass ( 1.2.840.113556.1.5.9 NAME 'user'
        DESC 'a user'
        SUP inetOrgPerson STRUCTURAL
        MUST ( cn )
        MAY ( userPassword $ memberOf $ userAccountControl ) )

" >> /etc/ldap/schema/new-attributes.schema

sudo service slapd restart

# Import our users
#ldapadd -x -w openstack -D"cn=admin,dc=cook,dc=book" -f /vagrant/cookbook.ldif