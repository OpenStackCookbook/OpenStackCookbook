# Install apt-cacher
export DEBIAN_FRONTEND=noninteractive
apt-get update && sudo apt-get install apt-cacher-ng -y

# Setup our repo's
sudo apt-get install python-software-properties -y
sudo add-apt-repository ppa:ubuntu-cloud-archive/grizzly-staging
sudo apt-get update
sudo apt-get install iftop iptraf vim curl wget lighttpd -y

echo 'Acquire::http { Proxy "http://172.16.0.110:3142"; };' | sudo tee /etc/apt/apt.conf.d/01apt-cacher-ng-proxy

wget --quiet http://uec-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img -O /var/www/precise-server-cloudimg-amd64-disk1.img
