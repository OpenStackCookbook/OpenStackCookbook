## Test Container Sync Swift Setup
#### Environment
swift1 + keystone on 172.16.0.221<br>
swift2 + keystone on 172.16.0.222<br>
### Quick Start
```bash
vagrant ssh swift1
sudo -i
. swiftrc
swift stat
```
#### Set up Container Sync
```bash
. swiftrc

CONT2=$(swift -V2.0 -A http://swift2:5000/v2.0 -U cookbook:admin -K openstack stat | awk '/AUTH/ {print $2}')
CONT1=$(swift stat | awk '/AUTH/ {print $2}')

# Create 'container2' on '172.16.0.222' (swift2) with sync back to 'container1' 
# on '172.16.0.221' with key 'secret'
swift -V2.0 -A http://172.16.0.222:5000/v2.0 -U cookbook:admin -K openstack \
  post -t "http://172.16.0.221:8080/v1/${CONT1}/container1" -k 'secret' container2

# Create 'container1' on '172.16.0.221' (swift1) with sync back to 'container2' 
# on '172.16.0.222' with key 'secret'
swift post -t "http://172.16.0.222:8080/v1/${CONT2}/container2" -k 'secret' container1

# Upload a test file to swift1:/container1
dd if=/dev/zero of=/tmp/example-10M bs=1M count=10
swift upload container1 /tmp/example-10M

# Force a sync
swift-init container-sync once

# Check file exists on swift2:/container2
swift -V2.0 -A http://swift2:5000/v2.0 -U cookbook:admin -K openstack stat container2
swift -V2.0 -A http://swift2:5000/v2.0 -U cookbook:admin -K openstack list container2
```
