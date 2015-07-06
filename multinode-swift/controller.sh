#!/bin/bash

# controller.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)
#          Egle Sigler (ushnishtha@hotmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 3rd Edition
# Website: http://www.openstackcookbook.com/
# Scripts updated for Juno

# Source in common env vars
. /vagrant/common.sh

# The routeable IP of the node is on our eth1 interface
ETH1_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH2_IP=$(ifconfig eth2 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
ETH3_IP=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

PUBLIC_IP=${ETH3_IP}
INT_IP=${ETH1_IP}
ADMIN_IP=${ETH3_IP}

SWIFT_PROXY_SERVER=swift-proxy

#export LANG=C

# MySQL
export MYSQL_HOST=${ETH1_IP}
export MYSQL_ROOT_PASS=openstack
export MYSQL_DB_PASS=openstack

echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASS" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password seen true" | sudo debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again seen true" | sudo debconf-set-selections

sudo apt-get -y install mariadb-server python-mysqldb

sudo sed -i "s/^bind\-address.*/bind-address = 0.0.0.0/g" /etc/mysql/my.cnf
sudo sed -i "s/^#max_connections.*/max_connections = 512/g" /etc/mysql/my.cnf

# Skip Name Resolve
echo "[mysqld]
skip-name-resolve" > /etc/mysql/conf.d/skip-name-resolve.cnf


# UTF-8 Stuff
echo "[mysqld]
collation-server = utf8_general_ci
init-connect='SET NAMES utf8'
character-set-server = utf8" > /etc/mysql/conf.d/01-utf8.cnf

sudo service mysql restart

# Ensure root can do its job
mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"localhost\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"${MYSQL_HOST}\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"
mysql -u root -p${MYSQL_ROOT_PASS} -h localhost -e "GRANT ALL ON *.* to root@\"%\" IDENTIFIED BY \"${MYSQL_ROOT_PASS}\" WITH GRANT OPTION;"

mysqladmin -uroot -p${MYSQL_ROOT_PASS} flush-privileges






######################
# Chapter 1 KEYSTONE #
######################

# Create database
sudo apt-get -y install ntp keystone python-keyring

# Config Files
KEYSTONE_CONF=/etc/keystone/keystone.conf
SSL_PATH=/etc/ssl/

MYSQL_ROOT_PASS=openstack
MYSQL_KEYSTONE_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE keystone;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$MYSQL_KEYSTONE_PASS';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$MYSQL_KEYSTONE_PASS';"

sudo sed -i "s#^connection.*#connection = mysql://keystone:${MYSQL_KEYSTONE_PASS}@${MYSQL_HOST}/keystone#" ${KEYSTONE_CONF}
sudo sed -i 's/^#admin_token.*/admin_token = ADMIN/' ${KEYSTONE_CONF}
sudo sed -i 's,^#log_dir.*,log_dir = /var/log/keystone,' ${KEYSTONE_CONF}

sudo echo "use_syslog = True" >> ${KEYSTONE_CONF}
sudo echo "syslog_log_facility = LOG_LOCAL0" >> ${KEYSTONE_CONF}

sudo apt-get -y install python-keystoneclient

sudo keystone-manage ssl_setup --keystone-user keystone --keystone-group keystone
echo "
#[signing]
#certfile=/etc/keystone/ssl/certs/signing_cert.pem
#keyfile=/etc/keystone/ssl/private/signing_key.pem
#ca_certs=/etc/keystone/ssl/certs/ca.pem
#ca_key=/etc/keystone/ssl/private/cakey.pem
#key_size=2048
#valid_days=3650
#cert_subject=/C=US/ST=Unset/L=Unset/O=Unset/CN=172.16.0.200

[ssl]
enable = True
certfile = /etc/keystone/ssl/certs/keystone.pem
keyfile = /etc/keystone/ssl/private/keystonekey.pem
ca_certs = /etc/keystone/ssl/certs/ca.pem
cert_subject=/C=US/ST=Unset/L=Unset/O=Unset/CN=192.168.100.200
#cert_subject=/C=US/ST=Unset/L=Unset/O=Unset/CN=172.16.0.200
ca_key = /etc/keystone/ssl/certs/cakey.pem" | sudo tee -a ${KEYSTONE_CONF}

rm -rf /etc/keystone/ssl
sudo keystone-manage ssl_setup --keystone-user keystone --keystone-group keystone
sudo cp /etc/keystone/ssl/certs/ca.pem /etc/ssl/certs/ca.pem
sudo c_rehash /etc/ssl/certs/ca.pem
sudo cp /etc/keystone/ssl/certs/ca.pem /vagrant/ca.pem
sudo cp /etc/keystone/ssl/certs/cakey.pem /vagrant/cakey.pem

# This runs for both LDAP and non-LDAP configs
create_endpoints(){
  export ENDPOINT=${PUBLIC_IP}
  export INT_ENDPOINT=${INT_IP}
  export ADMIN_ENDPOINT=${ADMIN_IP}
  export SERVICE_TOKEN=ADMIN
  export SERVICE_ENDPOINT=https://${KEYSTONE_ADMIN_ENDPOINT}:35357/v2.0
  export PASSWORD=openstack
  export OS_CACERT=/vagrant/ca.pem
  export OS_KEY=/vagrant/cakey.pem

   # OpenStack Compute Nova API Endpoint
  keystone  service-create --name nova --type compute --description 'OpenStack Compute Service'

  # OpenStack Compute EC2 API Endpoint
  keystone  service-create --name ec2 --type ec2 --description 'EC2 Service'

  # Glance Image Service Endpoint
  keystone  service-create --name glance --type image --description 'OpenStack Image Service'

  # Keystone Identity Service Endpoint
  keystone  service-create --name keystone --type identity --description 'OpenStack Identity Service'

  # Cinder Block Storage Endpoint
  keystone  service-create --name volume --type volume --description 'Volume Service'

  # Neutron Network Service Endpoint
  keystone  service-create --name network --type network --description 'Neutron Network Service'

  # Swift Object Storage Endpoint
  keystone  service-create --name swift --type object-store --description 'Object Storage Service'

  # OpenStack Compute Nova API
  NOVA_SERVICE_ID=$(keystone  service-list | awk '/\ nova\ / {print $2}')

  PUBLIC="http://$ENDPOINT:8774/v2/\$(tenant_id)s"
  ADMIN="http://$ADMIN_ENDPOINT:8774/v2/\$(tenant_id)s"
  INTERNAL="http://$INT_ENDPOINT:8774/v2/\$(tenant_id)s"

  keystone  endpoint-create --region regionOne --service_id $NOVA_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

  # OpenStack Compute EC2 API
  EC2_SERVICE_ID=$(keystone  service-list | awk '/\ ec2\ / {print $2}')

  PUBLIC="http://$ENDPOINT:8773/services/Cloud"
  ADMIN="http://$ADMIN_ENDPOINT:8773/services/Admin"
  INTERNAL="http://$INT_ENDPOINT:8773/services/Cloud"

  keystone  endpoint-create --region regionOne --service_id $EC2_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

  # Glance Image Service
  GLANCE_SERVICE_ID=$(keystone  service-list | awk '/\ glance\ / {print $2}')

  PUBLIC="http://$ENDPOINT:9292/v2"
  ADMIN="http://$ADMIN_ENDPOINT:9292/v2"
  INTERNAL="http://$INT_ENDPOINT:9292/v2"

  keystone  endpoint-create --region regionOne --service_id $GLANCE_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

  # Keystone OpenStack Identity Service
  KEYSTONE_SERVICE_ID=$(keystone  service-list | awk '/\ keystone\ / {print $2}')

  PUBLIC="https://$ENDPOINT:5000/v2.0"
  ADMIN="https://$ADMIN_ENDPOINT:35357/v2.0"
  INTERNAL="https://$INT_ENDPOINT:5000/v2.0"

  keystone  endpoint-create --region regionOne --service_id $KEYSTONE_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

  # Cinder Block Storage Service
  CINDER_SERVICE_ID=$(keystone  service-list | awk '/\ volume\ / {print $2}')

  #Dynamically determine first three octets if user specifies alternative IP ranges.  Fourth octet still hardcoded
  CINDER_ENDPOINT=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' | sed 's/\.[0-9]*$/.211/')
  PUBLIC="http://$CINDER_ENDPOINT:8776/v1/%(tenant_id)s"
  ADMIN=$PUBLIC
  INTERNAL=$PUBLIC

  keystone  endpoint-create --region regionOne --service_id $CINDER_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

  # Neutron Network Service
  NEUTRON_SERVICE_ID=$(keystone  service-list | awk '/\ network\ / {print $2}')

  PUBLIC="http://$ENDPOINT:9696"
  ADMIN="http://$ADMIN_ENDPOINT:9696"
  INTERNAL="http://$INT_ENDPOINT:9696"

  keystone  endpoint-create --region regionOne --service_id $NEUTRON_SERVICE_ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL

  # Object Storage Service
  ID=$(keystone service-list | awk '/\ swift\ / {print $2}')

  PUBLIC_URL="http://$SWIFT_PROXY_SERVER:8080/v1/AUTH_\$(tenant_id)s"
  ADMIN_URL="http://$SWIFT_PROXY_SERVER:8080/v1/"
  INTERNAL_URL="http://$SWIFT_PROXY_SERVER:8080/v1/AUTH_\$(tenant_id)s"

  keystone endpoint-create --region RegionOne --service_id $ID --publicurl $PUBLIC_URL --adminurl $ADMIN_URL --internalurl $INTERNAL_URL

}

sudo stop keystone
sudo start keystone
sudo keystone-manage db_sync

export ENDPOINT=${PUBLIC_IP}
export INT_ENDPOINT=${INT_IP}
export ADMIN_ENDPOINT=${ADMIN_IP}
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=https://${KEYSTONE_ADMIN_ENDPOINT}:35357/v2.0
export PASSWORD=openstack

# admin role
keystone  role-create --name admin

# Member role
keystone  role-create --name Member

keystone  role-list

keystone  tenant-create --name cookbook --description "Default Cookbook Tenant" --enabled true

TENANT_ID=$(keystone  tenant-list | awk '/\ cookbook\ / {print $2}')

keystone  user-create --name admin --tenant_id $TENANT_ID --pass $PASSWORD --email root@localhost --enabled true

TENANT_ID=$(keystone  tenant-list | awk '/\ cookbook\ / {print $2}')

ROLE_ID=$(keystone  role-list | awk '/\ admin\ / {print $2}')

USER_ID=$(keystone  user-list | awk '/\ admin\ / {print $2}')

keystone  user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID

# Create the user
PASSWORD=openstack
keystone  user-create --name demo --tenant_id $TENANT_ID --pass $PASSWORD --email demo@localhost --enabled true

TENANT_ID=$(keystone  tenant-list | awk '/\ cookbook\ / {print $2}')

ROLE_ID=$(keystone  role-list | awk '/\ Member\ / {print $2}')

USER_ID=$(keystone  user-list | awk '/\ demo\ / {print $2}')

# Assign the Member role to the demo user in cookbook
keystone  user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID

create_endpoints

# Service Tenant
keystone  tenant-create --name service --description "Service Tenant" --enabled true

SERVICE_TENANT_ID=$(keystone  tenant-list | awk '/\ service\ / {print $2}')

keystone  user-create --name nova --pass nova --tenant_id $SERVICE_TENANT_ID --email nova@localhost --enabled true

keystone  user-create --name glance --pass glance --tenant_id $SERVICE_TENANT_ID --email glance@localhost --enabled true

keystone  user-create --name keystone --pass keystone --tenant_id $SERVICE_TENANT_ID --email keystone@localhost --enabled true

keystone  user-create --name cinder --pass cinder --tenant_id $SERVICE_TENANT_ID --email cinder@localhost --enabled true

keystone  user-create --name neutron --pass neutron --tenant_id $SERVICE_TENANT_ID --email neutron@localhost --enabled true

keystone  user-create --name swift --pass swift --tenant_id $SERVICE_TENANT_ID --email swift@localhost --enabled true

# Get the nova user id
NOVA_USER_ID=$(keystone  user-list | awk '/\ nova\ / {print $2}')

# Get the admin role id
ADMIN_ROLE_ID=$(keystone  role-list | awk '/\ admin\ / {print $2}')

# Assign the nova user the admin role in service tenant
keystone  user-role-add --user $NOVA_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Get the glance user id
GLANCE_USER_ID=$(keystone  user-list | awk '/\ glance\ / {print $2}')

# Assign the glance user the admin role in service tenant
keystone  user-role-add --user $GLANCE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Get the keystone user id
KEYSTONE_USER_ID=$(keystone  user-list | awk '/\ keystone\ / {print $2}')

# Assign the keystone user the admin role in service tenant
keystone  user-role-add --user $KEYSTONE_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Get the cinder user id
CINDER_USER_ID=$(keystone  user-list | awk '/\ cinder \ / {print $2}')

# Assign the cinder user the admin role in service tenant
keystone  user-role-add --user $CINDER_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Create neutron service user in the services tenant
NEUTRON_USER_ID=$(keystone  user-list | awk '/\ neutron \ / {print $2}')

# Grant admin role to neutron service user
keystone  user-role-add --user $NEUTRON_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Create neutron service user in the services tenant
SWIFT_USER_ID=$(keystone  user-list | awk '/\ swift \ / {print $2}')

# Grant admin role to neutron service user
keystone  user-role-add --user $SWIFT_USER_ID --role $ADMIN_ROLE_ID --tenant_id $SERVICE_TENANT_ID

# Sort out keys for root user
sudo ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
rm -f /vagrant/id_rsa*
sudo cp /root/.ssh/id_rsa /vagrant
sudo cp /root/.ssh/id_rsa.pub /vagrant
cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys


# Write out the /etc/swift/swift.conf file to /vagrant so proxy and storage nodes can pick up

# Setup /etc/swift/swift.conf
SWIFT_PREFIX_HASH=`< /dev/urandom tr -dc A-Za-z0-9_ | head -c16; echo`
SWIFT_SUFFIX_HASH=`< /dev/urandom tr -dc A-Za-z0-9_ | head -c16; echo`
sudo cat > /vagrant/swift.conf  <<EOF
[swift-hash]
# Random unique string used on all nodes
swift_hash_path_prefix=$SWIFT_PREFIX_HASH
swift_hash_path_suffix=$SWIFT_SUFFIX_HASH
EOF
