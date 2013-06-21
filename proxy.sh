# Install apt-cacher
export DEBIAN_FRONTEND=noninteractive
apt-get update && sudo apt-get install apt-cacher-ng -y

# Use host for cache directory, makes cache directory persistent between proxy server rebuilds
mkdir -p /vagrant/apt-cacher-ng
rm -rf /var/cache/apt-cacher-ng
cd /vagrant
cp -R apt-cacher-ng/ /var/cache
chown -R apt-cacher-ng:apt-cacher-ng /var/cache/apt-cacher-ng

# Setup our repo's
sudo apt-get install python-software-properties -y
sudo add-apt-repository ppa:ubuntu-cloud-archive/grizzly-staging
sudo apt-get update
sudo apt-get install iftop iptraf vim curl wget lighttpd -y

echo 'Acquire::http { Proxy "http://172.16.0.110:3142"; };' | sudo tee /etc/apt/apt.conf.d/01apt-cacher-ng-proxy

CIRROS="cirros-0.3.0-x86_64-disk.img"
UBUNTU="precise-server-cloudimg-amd64-disk1.img"

if [[ -f /vagrant/${CIRROS} ]]
then
	# Copy from local host
	rm -f /var/www/${CIRROS}
	cp /vagrant/${CIRROS} /var/www/${CIRROS}
else
	# Download then store on local host for next time
	wget --quiet https://launchpad.net/cirros/trunk/0.3.0/+download/${CIRROS} -O /var/www/${CIRROS}
	cp /var/www/${CIRROS} /vagrant/${CIRROS}
fi

if [[ -f /vagrant/${UBUNTU} ]]
then
	# Copy from local host
	rm -f /var/www/${UBUNTU}
	cp /vagrant/${UBUNTU} /var/www/${UBUNTU}
else
	# Download then store on local host for next time
	wget --quiet http://uec-images.ubuntu.com/precise/current/${UBUNTU} -O /var/www/${UBUNTU}
	cp /var/www/${UBUNTU} /vagrant/${UBUNTU}
fi
