# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_COMMAND = ARGV[0]

box = "bento/ubuntu-24.04"
provider = "virtualbox"
hostname = "test"
python_version = "python3.12"
ansible_verbose_level = ENV.fetch('VAGRANT_ANSIBLE_VERBOSE_LEVEL') { 'v' }
forward_ports = ENV.fetch("VAGRANT_FORWARD_PORTS") { "true" }
home_dir = ENV["HOME"]
username = "pihole"

# Convert string to boolean
def convert_to_boolean(string)
    string.casecmp("true").zero?
end

# Check if the VM is already provisioned
def provisioned?(vm_name, provider)
    File.exist?(".vagrant/machines/#{vm_name}/#{provider}/action_provision")
end

Vagrant.configure("2") do |config|
    vm_box = "#{box}"

    config.vm.box_download_insecure = true
    config.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 2
        v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
        v.customize [ "modifyvm", :id, "--cpuexecutioncap", "50" ]
        v.customize [ "modifyvm", :id, "--nested-hw-virt", "on" ]
    end

    config.ssh.insert_key = false
    config.ssh.verify_host_key = false

    if provisioned?("#{hostname}", "#{provider}")
        if VAGRANT_COMMAND == "ssh"
            config.ssh.username = "#{username}"
        else
            config.ssh.username = "vagrant"
        end
        config.ssh.private_key_path = ["#{home_dir}/.vagrant.d/insecure_private_keys/vagrant.key.ed25519"]
    end

    if "#{convert_to_boolean(forward_ports)}"
        ports = [{guest: 80, host: 8080},{guest: 443, host: 8443},{guest: 53, host: 9053},{guest: 51820, host: 51820}]
        ports.each do |port|
            config.vm.network "forwarded_port", guest: port[:guest], host: port[:host]
        end
    end

    config.vm.define "#{hostname}" do |c|
        c.vm.box = vm_box
        c.vm.hostname = "#{hostname}"
        c.vm.provision "shell",
            inline: "sudo apt-get update && sudo apt-get upgrade -y",
            run: "always"
        c.vm.provision "shell", inline: <<-EOC
            systemctl is-active --quiet sshd.service
            if [ $? == 0 ]; then
                sudo sed -i -e "\\#PasswordAuthentication yes# s#PasswordAuthentication no#g" /etc/ssh/sshd_config
                sudo systemctl restart sshd.service
            fi
            printf "finished initial shell config\n"
        EOC
        c.vm.provision "ansible" do |ansible|
            ansible.compatibility_mode = "2.0"
            ansible.playbook    = "./ansible/playbook.yml"
            ansible.extra_vars  = { ansible_python_interpreter:"/usr/bin/python3" }
            ansible.verbose     = "#{ansible_verbose_level}"
        end
    end
end
