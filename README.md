Vagrant scripts used by the OpenStack Cloud Computing Cookbook 2nd Edition<br>
Authors: Kevin Jackson (@itarchitectkev)  & Cody Bunch (@cody_bunch)<br>
<br>
SCRIPTS NOW UPDATED FOR ICEHOUSE!<br>
<br>
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
<br>
Website: http://www.openstackcookbook.com/<br>
Purchase: http://www.packtpub.com/openstack-cloud-computing-cookbook-second-edition/book<br>
Or on Amazon UK: http://t.co/qlJsxjexx8 <br>
<br>
<br>
Requirements:
* Vagrant 1.4+
* VirtualBox 4.3+
<br>
<br>To use vagrant-cachier:
<br>  vagrant plugin install vagrant-cachier
<br>
<br>
Quick Start<br>
git clone https://github.com/OpenStackCookbook/OpenStackCookbook.git<br>
cd OpenStackCookbook<br>
git checkout icehouse<br>
vagrant up<br>
vagrant ssh controller
. /vagrant/openrc<br>
nova service list<br>
nova list<br>
nova image-list<br>
neutron agent-list<br>
neutron net-list
<br>
OpenStack Dashboard (Horizon) is available at http://172.16.0.200/
<br>
