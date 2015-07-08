#!/bin/bash

# sort out keys for root user
sudo ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
rm -f /vagrant/id_rsa*
sudo cp /root/.ssh/id_rsa /vagrant
sudo cp /root/.ssh/id_rsa.pub /vagrant
cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

# Write out /root/.ssh/config
echo "
BatchMode yes
CheckHostIP no
StrictHostKeyChecking no" > /root/.ssh/config
chmod 0600 /root/.ssh/config
