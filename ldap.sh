#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
source /vagrant/openrc

# Install OpenLDAP
echo -e " \
slapd    slapd/internal/generated_adminpw    password	openstack
slapd    slapd/password2    password	openstack
slapd    slapd/internal/adminpw    password	openstack
slapd    slapd/password1    password	openstack
" | sudo debconf-set-selections

sudo apt-get install -y slapd ldap-utils expect

# Check that it's working
sudo slapcat 

# Let's pull tenants out of keystone, dump them into ldap
SUFFIX='dc=cook,dc=book'
LDIF='/tmp/cookbook.ldif'

echo -n > $LDIF

# Make our OUs
echo "dn: ou=Roles,$SUFFIX" >> $LDIF
echo "objectclass:organizationalunit" >> $LDIF
echo "ou: Roles" >> $LDIF
echo "description: generic groups branch" >> $LDIF
echo -e "\n" >> $LDIF

echo "dn: ou=Users,$SUFFIX" >> $LDIF
echo "objectclass:organizationalunit" >> $LDIF
echo "ou: Users" >> $LDIF
echo "description: generic groups branch" >> $LDIF
echo -e "\n" >> $LDIF

echo "dn: ou=Groups,$SUFFIX" >> $LDIF
echo "objectclass:organizationalunit" >> $LDIF
echo "ou: Groups" >> $LDIF
echo "description: generic groups branch" >> $LDIF
echo -e "\n" >> $LDIF

# Roles
for line in `keystone role-list | awk '($4 != "name") && ($4 != "") {print $4}'`
do
	CN=$line
	echo "dn: cn=$CN,ou=Roles,$SUFFIX" >> $LDIF
	echo "objectClass: organizationalRole" >> $LDIF
	echo "cn: $CN" >> $LDIF
	echo -e "\n" >> $LDIF
done

# Users
for line in `keystone user-list | awk '($4 != "name") && ($4 != "") {print $4}'`
do
	CN=$line
	echo "dn: cn=$CN,ou=Users,$SUFFIX" >> $LDIF
	echo "objectClass: inetOrgPerson" >> $LDIF
	echo "cn: $CN" >> $LDIF
	echo "sn: cookbook" >> $LDIF
	echo -e "\n" >> $LDIF
done

# Tenants
for line in `keystone tenant-list | awk '($4 != "name") && ($4 != "") {print $4}'`
do
	CN=$line
	echo "dn: cn=$CN,ou=Groups,$SUFFIX" >> $LDIF
	echo "objectClass: groupOfNames" >> $LDIF
	echo "member: cn=admin,$SUFFIX" >> $LDIF
	echo "cn: $CN" >> $LDIF
	echo -e "\n" >> $LDIF
done

# Import those into LDAP
expect<<EOF
spawn ldapadd -x -D cn=admin,dc=cook,dc=book -W -f /tmp/cookbook.ldif
expect "Enter LDAP Password:"
send "openstack\n"
expect eof
EOF

# Configure Keystone for LDAP
