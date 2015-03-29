#!/bin/bash

# install-rabbitmq.sh

# Authors: Kevin Jackson (kevin@linuxservices.co.uk)
#          Cody Bunch (bunchc@gmail.com)
#          Egle Sigler (ushnishtha@hotmail.com)

# Vagrant scripts used by the OpenStack Cloud Computing Cookbook, 3rd Edition
# Website: http://www.openstackcookbook.com/
# Scripts updated for Juno

# Make ourselves a new rabbit.conf
cat > /etc/rabbitmq/rabbitmq.config <<EOF
[{rabbit, [{loopback_users, []}]}].
EOF

cat > /etc/rabbitmq/rabbitmq-env.conf <<EOF
RABBITMQ_NODE_PORT=5672
EOF

/etc/init.d/rabbitmq-server restart
