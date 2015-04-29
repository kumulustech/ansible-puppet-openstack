# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |provider,override|
#    override.ssh.private_key_path = "~/.ssh/id_rsa"
 #   override.ssh.username = 'root'
    override.vm.box = 'chef/centos-7.0'
  end

  config.vm.provider :digital_ocean do |provider,override|
    override.ssh.private_key_path = "~/.ssh/id_rsa"
    provider.token = "XXXXX"
    provider.image = "centos-7-0-x64"
    provider.region = "sfo1"
    provider.size = "1gb"
    provider.ssh_key_name = "YYYYY"
    override.vm.box = 'digital_ocean'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
    provider.ipv6 = true
    provider.private_networking = true
  end

  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  #config.vm.box = "base"
  config.vm.box = "base"

  config.vm.define "db1" do |db1|
    db1.vm.provision "ansible" do |ansible|
      ansible.playbook = "mysql.yml"
#      ansible.limit = "all"
    end
    config.vm.network :private_network, ip: '192.168.56.11'
  end

  config.vm.define "db2" do |db2|
    db2.vm.provision "ansible" do |ansible|
      ansible.playbook = "mysql.yml"
#      ansible.limit = "all"
    end
    config.vm.network :private_network, ip: '192.168.56.12'
  end

end
