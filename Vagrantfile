# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
LINUX_DIST = "ubuntu/xenial64"
BOX_VERSION = nil

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
  end
  config.vm.define :master do |master_config|
    master_config.vm.box = LINUX_DIST
    master_config.vm.box_version = BOX_VERSION
    master_config.vm.host_name = 'saltmaster.local'
    master_config.vm.network "private_network", ip: "192.168.50.10"
    master_config.vm.synced_folder "saltstack/salt/", "/srv/salt"
    master_config.vm.synced_folder "saltstack/pillar/", "/srv/pillar"
    master_config.vm.synced_folder "saltstack/etc/cloud.providers.d", "/etc/salt/cloud.providers.d"
    master_config.vm.synced_folder "saltstack/etc/cloud.profiles.d", "/etc/salt/cloud.profiles.d"
    master_config.vm.synced_folder "saltstack/etc/cloud.maps.d", "/etc/salt/cloud.maps.d"

    master_config.vm.provision :salt do |salt|
      salt.master_config = "saltstack/etc/master"
      salt.master_key = "saltstack/keys/master_minion.pem"
      salt.master_pub = "saltstack/keys/master_minion.pub"
      salt.minion_config = "saltstack/etc/minion_master"
      salt.minion_key = "saltstack/keys/master_minion.pem"
      salt.minion_pub = "saltstack/keys/master_minion.pub"

      salt.install_type = "stable"
      # salt.install_args = "v2016.11"
      salt.install_master = true
      salt.no_minion = false
      salt.verbose = true
      salt.colorize = true
      salt.bootstrap_options = "-P -c /tmp"
    end

    # see https://github.com/mitchellh/vagrant/issues/1673 for the reason
    # the following block exists
    master_config.vm.provision "fix-no-tty", type: "shell" do |shell|
      shell.inline = <<SCRIPT
sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile
SCRIPT
    end

    master_config.vm.provision :shell do |shell|
      shell.inline = <<SCRIPT
ln -sf /vagrant/saltstack/etc/cloud /etc/salt/cloud
SCRIPT
    end

    master_config.vm.provision :shell do |shell|
      shell.inline = <<SCRIPT
sudo apt update && sudo apt install -y lxc;
SCRIPT
    end

    master_config.vm.provision :shell do |shell|
      shell.inline = <<SCRIPT
sudo apt install -y salt-cloud python-pip; sudo pip install requests;
SCRIPT
    end

    master_config.vm.provision :shell do |shell|
      shell.inline = <<SCRIPT
sudo salt-key -ay saltmaster;
SCRIPT
    end

  end
end
