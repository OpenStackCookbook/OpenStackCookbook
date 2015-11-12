#!/bin/bash

dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=20G
losetup /dev/loop2 cinder-volumes
pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2
