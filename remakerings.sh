#!/bin/bash

cd /etc/swift
rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

# Object Ring
swift-ring-builder object.builder create 18 3 1
swift-ring-builder object.builder add r1z1-127.0.0.1:6010/sdb1 1
swift-ring-builder object.builder add r1z2-127.0.0.1:6020/sdb2 1
swift-ring-builder object.builder add r1z3-127.0.0.1:6030/sdb3 1
swift-ring-builder object.builder add r1z4-127.0.0.1:6040/sdb4 1
swift-ring-builder object.builder rebalance

# Container Ring
swift-ring-builder container.builder create 18 3 1
swift-ring-builder container.builder add r1z1-127.0.0.1:6011/sdb1 1
swift-ring-builder container.builder add r1z2-127.0.0.1:6021/sdb2 1
swift-ring-builder container.builder add r1z3-127.0.0.1:6031/sdb3 1
swift-ring-builder container.builder add r1z4-127.0.0.1:6041/sdb4 1
swift-ring-builder container.builder rebalance

# Account Ring
swift-ring-builder account.builder create 18 3 1
swift-ring-builder account.builder add r1z1-127.0.0.1:6012/sdb1 1
swift-ring-builder account.builder add r1z2-127.0.0.1:6022/sdb2 1
swift-ring-builder account.builder add r1z3-127.0.0.1:6032/sdb3 1
swift-ring-builder account.builder add r1z4-127.0.0.1:6042/sdb4 1
swift-ring-builder account.builder rebalance
