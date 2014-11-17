## OpenStack Cloud Computing Cookbook 2nd Edition
#### Supporting vagrant scripts
## Buy The Book
More information http://www.openstackcookbook.com/<br>
Purchase: http://www.packtpub.com/openstack-cloud-computing-cookbook-second-edition/book<br>
And at your favourite online store!

## Authors 
Kevin Jackson (@itarchitectkev)
Cody Bunch (@cody_bunch)

## Updates
SCRIPTS NOW UPDATED FOR <b>JUNO</b>!

## About The Book
The book covers:
* Understand, install, configure, and manage Nova, the OpenStack cloud compute resource
* Dive headfirst into managing software defined networks with the OpenStack networking project and Open vSwitch
* Install and configure, Keystone, the OpenStack identity & authentication service
* Install, configure and operate the OpenStack block storage project: Cinder
* Install and manage Swift, the highly scalable OpenStack object storage service
* Gain hands on experience with the OpenStack dashboard Horizon
* Explore different monitoring frameworks to ensure your OpenStack cloud is always online and performing optimally
* Automate your installations using Vagrant, Chef, and Puppet
* Create custom Windows and Linux images for use in your private cloud environment.

## Usage
### Requirements
* Vagrant 1.4+ http://www.vagrantup.com/
* VirtualBox 4.3+ http://www.virtualbox.org/

### vagrant-cachier (optional but recommended)
```bash
vagrant plugin install vagrant-cachier
```
### Quick Start
```bash
git clone https://github.com/OpenStackCookbook/OpenStackCookbook.git
cd OpenStackCookbook
git checkout juno
vagrant up
```
### Using OpenStack
```bash
vagrant ssh controller
. /vagrant/openrc
nova service list
nova list
nova image-list
neutron agent-list
neutron net-list
```
You can quickly run a demo script that creates a private tenant network, a floating network with a router and launches an instance running Ubuntu by issuing the following
```bash
/vagrant/demo.sh
```
### More information
Check out the blog post: http://openstackr.wordpress.com/2014/05/01/openstack-cloud-computing-cookbook-the-icehouse-scripts/
