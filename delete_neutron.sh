#!/bin/bash

nova list | egrep -v -i "id.*" | egrep -v "\+" | awk '{print $2}' | while read INSTANCE; do nova delete $INSTANCE; done
neutron router-list | egrep -v -i "id.*" | egrep -v "\+" | awk '{print $2}' | while read ROUTER; do neutron router-delete $ROUTER; done
neutron subnet-list | egrep -v -i "id.*" | egrep -v "\+" | awk '{print $2}' | while read SUBNET; do neutron subnet-delete $SUBNET; done
neutron net-list | egrep -v -i "id.*" | egrep -v "\+" | awk '{print $2}' | while read NET; do neutron net-delete $NET; done
