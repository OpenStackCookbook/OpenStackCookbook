# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
    'proxy'	=> [1, 110],
    'swift1'  => [1, 221],
    'swift2'  => [1, 222],
}

Vagrant.configure("2") do |config|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"

    #Default is 2200..something, but port 2200 is used by forescout NAC agent.
    config.vm.usable_port_range= 2800..2900 

    # Sync folder for proxy cache
    # config.vm.synced_folder "apt-cacher-ng/", "/var/cache/apt-cacher-ng"


    nodes.each do |prefix, (count, ip_start)|
        count.times do |i|
            hostname = "%s" % [prefix, (i+1)]

            config.vm.define "#{hostname}" do |box|
                box.vm.hostname = "#{hostname}.rpc"
   		# eth0 Nat (auto)
		# eth1 host network
                box.vm.network :private_network, ip: "172.16.0.#{ip_start+i}", :netmask => "255.255.0.0"

                box.vm.provision :shell, :path => "keystone.sh"
                box.vm.provision :shell, :path => "#{prefix}.sh"

                # If using Fusion
                box.vm.provider :vmware_fusion do |v|
                    v.vmx["memsize"] = 1024
        	    if prefix == "compute"
	              	v.vmx["memsize"] = 2048
	            elsif prefix == "proxy"
    	                v.vmx["memsize"] = 512
	            end
                end

                # Otherwise using VirtualBox
                box.vm.provider :virtualbox do |vbox|
	            # Defaults
                    vbox.customize ["modifyvm", :id, "--memory", 2048]
                    vbox.customize ["modifyvm", :id, "--cpus", 2]
                end
            end
        end
    end
end
