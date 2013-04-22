vagrant destroy -f controller
vagrant destroy -f compute
vagrant destroy -f iscsi
vagrant destroy -f swift
vagrant up --provider=vmware_fusion
