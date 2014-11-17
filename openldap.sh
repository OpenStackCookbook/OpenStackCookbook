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
dn: ou=Groups,dc=cook,dc=book
objectClass: organizationalUnit
ou: Groups

dn: ou=Users,dc=cook,dc=book
objectClass: organizationalUnit
ou: Users

dn: ou=Roles,dc=cook,dc=book
objectClass: organizationalUnit
ou: Roles

dn: ou=Projects,dc=cook,dc=book
objectClass: organizationalUnit
ou: Projects

dn: cn=9fe2ff9ee4384b1894a90878d3e92bab,ou=Roles,dc=cook,dc=book
objectClass: organizationalRole
ou: _member_
cn: 9fe2ff9ee4384b1894a90878d3e92bab" >> /tmp/openstack.ldif
echo "doing the add thing"

ldapadd -x -w openstack -D"cn=admin,dc=cook,dc=book" -f /tmp/openstack.ldif