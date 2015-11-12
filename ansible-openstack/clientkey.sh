#!/bin/bash

ssh-keyscan controller >> ~/.ssh/known_hosts
mkdir -p --mode=0700 /root/.ssh
cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
cp /vagrant/id_rsa* ~/.ssh/

# Write out /root/.ssh/config
echo "
BatchMode yes
CheckHostIP no
StrictHostKeyChecking no" > /root/.ssh/config
chmod 0600 /root/.ssh/config
