# swift-proxy.sh

source /vagrant/common.sh

swift_proxy_install() {
	# Install some packages:
	sudo apt-get -y install swift swift-proxy memcached python-keystoneclient python-swiftclient curl python-webob
	sudo service ntp restart

	# Create signing directory & Set owner to swift
	mkdir /var/swift-signing
	chown -R swift /var/swift-signing

	# Create cache directory & set owner to swift
	mkdir -p /var/cache/swift
	chown -R swift:swift /var/cache/swift

	mkdir -p /etc/swift
	chown -R swift:swift /etc/swift
	
}

swift_proxy_configure(){
  # /etc/swift/swift.conf
  cp /vagrant/swift.conf /etc/swift/swift.conf

# Configure the Swift Proxy Server
sudo cat > /etc/swift/proxy-server.conf <<EOF
[DEFAULT]
bind_port = 8080
user = swift
swift_dir = /etc/swift
log_level = DEBUG

[pipeline:main]
# Order of execution of modules defined below
pipeline = catch_errors healthcheck cache authtoken keystone proxy-server

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = true
set log_name = swift-proxy
set log_facility = LOG_LOCAL0
set log_level = INFO
set access_log_name = swift-proxy
set access_log_facility = SYSLOG
set access_log_level = INFO
set log_headers = True

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:cache]
use = egg:swift#memcache
set log_name = cache

[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory

# Delaying the auth decision is required to support token-less
# usage for anonymous referrers ('.r:*').
delay_auth_decision = true
 
# auth_* settings refer to the Keystone server
auth_uri = https://${KEYSTONE_ADMIN_ENDPOINT}:35357/v2.0/
identity_uri = https://${KEYSTONE_ADMIN_ENDPOINT}:5000
insecure = True

# the service tenant and swift username and password created in Keystone
admin_tenant_name = service
admin_user = swift
admin_password = swift

signing_dir = /var/swift-signing

[filter:keystone]
use = egg:swift#keystoneauth
operator_roles = admin, Member
#reseller_prefix = AUTH_
EOF


# Create dispersion.conf
sudo tee /etc/swift/dispersion.conf >/dev/null <<EOF
[dispersion]
auth_url = http://${ENDPOINT}:5000/v2.0/
auth_user = cookbook:admin
auth_key = openstack
EOF

sudo chown -L -R swift.swift /etc/swift /srv/node /run/swift

}

copy_ssh_keys() {
  # The controller creates a new ssh keypair on boot
  sudo mkdir --mode=0700 -p /root/.ssh/
  sudo cp /vagrant/id_rsa /root/.ssh/
  sudo cp /vagrant/id_rsa.pub /root/.ssh/
  cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

  echo "
BatchMode yes
CheckHostIP no
StrictHostKeyChecking no" > /root/.ssh/config
chmod 0600 /root/.ssh/config
}

swift_make_rings() {
  echo "This step can take a while. Be patient."
  sudo cp /vagrant/remakerings.sh /usr/local/bin/
  sudo chmod +x /usr/local/bin/remakerings.sh
  sudo /usr/local/bin/remakerings.sh

  # Copy rings to storage nodes
  for s in {1..5}
  do
    sudo scp /etc/swift/*.gz swift-0${s}:/etc/swift
  done
}

swift_restart(){
  # Start the Swift services
  for s in {1..5}
  do
    sudo ssh swift-0${s} swift-init all restart
  done
	
  sudo service swift-proxy restart
}

# Main
swift_proxy_install
swift_proxy_configure
copy_ssh_keys
swift_make_rings
swift_restart
