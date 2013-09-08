# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
    'proxy'	=> [1, 110],
    'controller'  => [1, 200],
    'network'  => [1, 202],
    'compute'  => [1, 201],
    'swift'   => [1, 210],
    'cinder'   => [1, 211],
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
            #hostname = "%s-%02d" % [prefix, (i+1)]
            hostname = "%s" % [prefix, (i+1)]

            config.vm.define "#{hostname}" do |box|
                box.vm.hostname = "#{hostname}.book"
                box.vm.network :private_network, ip: "172.16.0.#{ip_start+i}", :netmask => "255.255.0.0"
                box.vm.network :private_network, ip: "10.10.0.#{ip_start+i}", :netmask => "255.255.0.0" 
		box.vm.network :private_network, ip: "192.168.100.#{ip_start+i}", :netmask => "255.255.255.0" 

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
                    vbox.customize ["modifyvm", :id, "--memory", 1024]
                    vbox.customize ["modifyvm", :id, "--cpus", 1]
		    if prefix == "compute"
                    	vbox.customize ["modifyvm", :id, "--memory", 3128]
                        vbox.customize ["modifyvm", :id, "--cpus", 2]
			vbox.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
		    elsif prefix == "controller"
		        vbox.customize ["modifyvm", :id, "--memory", 2048]
		    elsif prefix == "network"
		        vbox.customize ["modifyvm", :id, "--memory", 1024]
			vbox.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
		    elsif prefix == "proxy"
		        vbox.customize ["modifyvm", :id, "--memory", 512]
		    elsif prefix == "swift"
		        vbox.customize ["modifyvm", :id, "--memory", 2048]
		    end
                end
            end
        end
    end
end
