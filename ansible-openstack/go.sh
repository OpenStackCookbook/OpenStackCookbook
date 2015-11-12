#!/bin/bash
rm -f vagrant.out
vagrant destroy -f
vagrant up | tee -a vagrant.out
