Vagrant.configure(2) do |config|
  config.vm.box = "hashicorp-training/terraform-nomad"

  # Disable checking for updates to save bandwidth.
  config.vm.box_check_update = false

  # Give the VM more memory, CPU, and a better NIC.
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpus", "2"]
    v.customize ["modifyvm", :id, "--memory", "4096"]
    v.customize ["modifyvm", :id, "--nictype1", "virtio"]
  end

  # Support for a Docker based setup
  config.vm.provider "docker" do |d|
    d.image = "ubuntu:14.04"
  end
end
