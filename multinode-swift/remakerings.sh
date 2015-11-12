#!/bin/bash

cd /etc/swift
rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

# Object Ring
swift-ring-builder object.builder create 18 3 1
swift-ring-builder object.builder add r1z1-172.16.0.221:6000/sdb1 1
swift-ring-builder object.builder add r1z1-172.16.0.222:6000/sdb1 1
swift-ring-builder object.builder add r1z1-172.16.0.223:6000/sdb1 1
swift-ring-builder object.builder add r1z1-172.16.0.224:6000/sdb1 1
swift-ring-builder object.builder add r1z1-172.16.0.225:6000/sdb1 1
swift-ring-builder object.builder rebalance

# Container Ring
swift-ring-builder container.builder create 18 3 1
swift-ring-builder container.builder add r1z1-172.16.0.221:6001/sdb1 1
swift-ring-builder container.builder add r1z1-172.16.0.222:6001/sdb1 1
swift-ring-builder container.builder add r1z1-172.16.0.223:6001/sdb1 1
swift-ring-builder container.builder add r1z1-172.16.0.224:6001/sdb1 1
swift-ring-builder container.builder add r1z1-172.16.0.225:6001/sdb1 1
swift-ring-builder container.builder rebalance

# Account Ring
swift-ring-builder account.builder create 18 3 1
swift-ring-builder account.builder add r1z1-172.16.0.221:6002/sdb1 1
swift-ring-builder account.builder add r1z1-172.16.0.222:6002/sdb1 1
swift-ring-builder account.builder add r1z1-172.16.0.223:6002/sdb1 1
swift-ring-builder account.builder add r1z1-172.16.0.224:6002/sdb1 1
swift-ring-builder account.builder add r1z1-172.16.0.225:6002/sdb1 1
swift-ring-builder account.builder rebalance
