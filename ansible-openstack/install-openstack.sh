#!/bin/bash

#set -ex

#TAG=10.1.4
TAG=11.0.3

COMPUTES="compute-01"
#compute-02"

CONTROLLERS="controller-01
controller-02
controller-03"

HOSTS="logging
$COMPUTES
$CONTROLLERS"

RETRY=5

ap() {
	d=$(date)
	echo "Running $@ $d"
	#ansible-playbook -e @/etc/openstack_deploy/user_variables.yml "$@"
	openstack-ansible "$@"
}


get_playbooks() {
	cd /opt
	rm -rf os-ansible-deployment
	git clone -b ${TAG} https://github.com/stackforge/os-ansible-deployment.git
	# Fix the http/https rackspace repo error
        sed -i 's,http\:\/\/rpc\-repo,https://rpc-repo,g' /opt/os-ansible-deployment/playbooks/inventory/group_vars/all.yml
}

install_ansible() {
	# pip install -r /opt/os-ansible-deployment/requirements.txt
	cd /opt/os-ansible-deployment
	scripts/bootstrap-ansible.sh
	cd /opt
}

configure_deployment() {
	cp -R /opt/os-ansible-deployment/etc/openstack_deploy /etc

	cp /vagrant/openstack_user_config.yml /etc/openstack_deploy/openstack_user_config.yml
	cp /vagrant/user_variables.yml /etc/openstack_deploy/user_variables.yml

	# Has pointers to proxy and local repo
	cp /vagrant/user_group_vars.yml /etc/openstack_deploy/user_group_vars.yml

	cd /opt/os-ansible-deployment
        scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml
	
	# Remove swift artifact
	rm -f /etc/openstack_deploy/conf.d/swift.yml
}

install_foundation_playbooks() {
	rm -f /root/*.retry
	cd /opt/os-ansible-deployment/playbooks
	ap setup-hosts.yml
	
	count=0
	while [[ ${count} -lt ${RETRY} ]] && [[ -f /root/setup-hosts.retry ]]
	do
		sleep 60
		let count=count+1
		ap -vvv setup-hosts.yml
		if [[ $? -eq 0 ]]; then break; fi

		if [[ ${count} -eq ${RETRY} ]]
		then
			echo "Exiting on openstack-hosts."
			exit 1
		fi
	done
}


install_infra_playbooks() {
	rm -f /root/*.retry
	cd /opt/os-ansible-deployment/playbooks
	ap haproxy-install.yml

	# Put stats in place http://172.16.0.201:9000/stats admin:openstack
	cp /vagrant/haproxy_stats /etc/haproxy/conf.d/haproxy_stats
	/etc/init.d/haproxy restart

	# Hack: Fix strange vcpu issue (https://bugs.launchpad.net/openstack-ansible/+bug/1400444)
	sed -i 's/galera_wsrep_slave_threads.*/galera_wsrep_slave_threads: 2/g' /opt/os-ansible-deployment/playbooks/roles/galera_server/defaults/main.yml
	sed -i 's/all_calculated_max_connections.append.*/all_calculated_max_connections.append(1 * 100) %}/' /opt/os-ansible-deployment/playbooks/roles/galera_server/templates/my.cnf.j2
	
	# galera_innodb_buffer_pool_size: 4096M is too big for VMs
	sed -i 's/galera_innodb_buffer_pool_size.*/galera_innodb_buffer_pool_size: 1024M/g' /opt/os-ansible-deployment/playbooks/roles/galera_server/defaults/main.yml

	ap setup-infrastructure.yml

	count=0
	while [[ ${count} -lt ${RETRY} ]] && [[ -f /root/setup-infrastructure.retry ]]
	do
		sleep 60
		let count=count+1
		ap -vvv setup-infrastructure.yml
		if [[ $? -eq 0 ]]; then break; fi

		if [[ ${count} -eq ${RETRY} ]]
		then
			echo "Exiting on openstack-infrastructure."
			exit 1
		fi
	done
}

configure_galera_for_haproxy() {
	# Add haproxy user to be accessed from logging
	# Add root user with password from user_secrets to be accessed from logging with privileges

	G1=$(awk '/controller-01_galera/ {print $1}' /etc/hosts)	
	PASS=$(awk '/galera_root_password/ {print $2}' /etc/openstack_deploy/user_secrets.yml)
	ssh ${G1} "mysql -u root -h localhost -e \"GRANT ALL ON *.* to haproxy@'logging';\""
	ssh ${G1} "mysql -u root -h localhost -e \"GRANT ALL ON *.* to root@'logging' IDENTIFIED BY '${PASS}' WITH GRANT OPTION;\""
}

check_galera() {
	apt-get -y install mariadb-client
	# MySQL Test
	PASS=$(awk '/galera_root_password/ {print $2}' /etc/openstack_deploy/user_secrets.yml)
	mysql -uroot -p${PASS} -h 172.16.0.201 -e 'show status;'
	STATUS=$?
	if [[ $STATUS != 0 ]]
	then
		echo "Check MariaDB/Galera. Unable to connect."
		exit 1
	fi
}

install_openstack_playbooks() {
	rm -f /root/*.retry
	cd /opt/os-ansible-deployment/playbooks
	ap setup-openstack.yml

	count=0
	while [[ ${count} -lt ${RETRY} ]] && [[ -f /root/setup-openstack.retry ]]
	do
		sleep 120
		let count=count+1
		ap -vvv setup-openstack.yml
		if [[ $? -eq 0 ]]; then break; fi

		if [[ ${count} -eq ${RETRY} ]]
		then
			echo "Exiting on openstack-setup."
			exit 1
		fi
	done
}

run_playbooks() {
	cd /opt/os-ansible-deployment
	scripts/run-playbooks.sh
}


fixup_flat_networking() {
	for a in $COMPUTES; do ssh -n ${a} "sed -i 's/vlan:br-vlan/vlan:eth11/g' /etc/neutron/plugins/ml2/ml2_conf.ini; restart neutron-linuxbridge-agent"; done
}

get_playbooks
install_pip
install_ansible
configure_deployment
run_playbooks
#install_foundation_playbooks
#install_infra_playbooks
#configure_galera_for_haproxy
#check_galera
#install_openstack_playbooks
fixup_flat_networking

# List Inventory Contents
#~/ansible-lxc-rpc/scripts/inventory-manage.py -f /etc/openstack_deploy/rpc_inventory.json --list-host
