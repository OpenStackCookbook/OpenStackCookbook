# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
    'controller'  => [1, 200],
    'network'  => [1, 201],
    'compute'  => [1, 202],
    'compute2'  => [1, 203],
    # 'swift'   => [1, 210],
    'cinder'   => [1, 211],
}

Vagrant.configure("2") do |config|
    
    # Virtualbox
    config.vm.box = "bunchc/trusty-x64"
    config.vm.synced_folder ".", "/vagrant", type: "nfs"

    # VMware Fusion / Workstation
    config.vm.provider "vmware_fusion" or config.vm.provider "vmware_workstation" do |vmware, override|
      override.vm.box = "bunchc/trusty-x64"
      override.vm.synced_folder ".", "/vagrant", type: "nfs"

      # Fusion Performance Hacks
      vmware.vmx["logging"] = "FALSE"
      vmware.vmx["MemTrimRate"] = "0"
      vmware.vmx["MemAllowAutoScaleDown"] = "FALSE"
      vmware.vmx["mainMem.backing"] = "swap"
      vmware.vmx["sched.mem.pshare.enable"] = "FALSE"
      vmware.vmx["snapshot.disabled"] = "TRUE"
      vmware.vmx["isolation.tools.unity.disable"] = "TRUE"
      vmware.vmx["unity.allowCompostingInGuest"] = "FALSE"
      vmware.vmx["unity.enableLaunchMenu"] = "FALSE"
      vmware.vmx["unity.showBadges"] = "FALSE"
      vmware.vmx["unity.showBorders"] = "FALSE"
      vmware.vmx["unity.wasCapable"] = "FALSE"
      vmware.vmx["vhv.enable"] = "TRUE"
    end


    #Default is 2200..something, but port 2200 is used by forescout NAC agent.
    config.vm.usable_port_range= 2800..2900 

    if Vagrant.has_plugin?("vagrant-cachier")
        config.cache.scope = :box
        config.cache.enable :apt
        config.cache.synced_folder_opts = {
          type: :nfs,
          mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
        }
    else
        puts "[-] WARN: This would be much faster if you ran vagrant plugin install vagrant-cachier first"
    end

    nodes.each do |prefix, (count, ip_start)|
        count.times do |i|
            #hostname = "%s-%02d" % [prefix, (i+1)]
            hostname = "%s" % [prefix, (i+1)]

            config.vm.define "#{hostname}" do |box|
                box.vm.hostname = "#{hostname}.book"
                box.vm.network :private_network, ip: "172.16.0.#{ip_start+i}", :netmask => "255.255.0.0"
                box.vm.network :private_network, ip: "10.10.0.#{ip_start+i}", :netmask => "255.255.255.0" 
            	box.vm.network :private_network, ip: "192.168.100.#{ip_start+i}", :netmask => "255.255.255.0" 

                box.vm.provision :shell, :path => "#{prefix}.sh"

                # If using Fusion
                box.vm.provider :vmware_fusion do |v|
                  v.vmx["memsize"] = 1024
                  if prefix == "compute" or prefix == "controller" or prefix == "swift"
	            v.vmx["memsize"] = 3172
                    v.vmx["numvcpus"] = "2"
                  end
                end

                # If using Workstation
                box.vm.provider :vmware_workstation do |v|
                  v.vmx["memsize"] = 1024
                  if prefix == "compute" or prefix == "controller" or prefix == "swift"
                    v.vmx["memsize"] = 3172
                    v.vmx["numvcpus"] = "2"
                  end
                end

                # Otherwise using VirtualBox
                box.vm.provider :virtualbox do |vbox|
                  # Defaults
                  vbox.customize ["modifyvm", :id, "--memory", 1024]
                  vbox.customize ["modifyvm", :id, "--cpus", 1]
	          if prefix == "compute" or prefix == "controller" or prefix == "swift"
                    vbox.customize ["modifyvm", :id, "--memory", 3172]
                    vbox.customize ["modifyvm", :id, "--cpus", 2]
                  end
                  vbox.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
                  vbox.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
                end
            end
        end
    end
end
