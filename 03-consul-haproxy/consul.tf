// This is the Consul Terraform module. This module is actually bundled within
// Consul at https://github.com/hashicorp/consul in the Terraform folder.
module "consul" {
  // This is the source of the Consul module.
  source = "github.com/sethvargo/tf-consul-atlas-join"

  // This is the specific AMI id to use for the Consul servers.
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  // This tells the Consul module to create 3 servers.
  servers = 3

  // This tells the Consul module to launch inside our VPC
  subnet_id      = "${aws_subnet.terraform-tutorial.id}"
  security_group = "${aws_security_group.terraform-tutorial.id}"

  // These two arguments use outputs from another module. The ssh_keys module
  // we have been using outputs the key name and key path. The Consul module
  // takes those values as arguments.
  key_name         = "${aws_key_pair.terraform-tutorial.key_name}"
  private_key_path = "${path.module}/${var.private_key_path}"

  // These variables are provided via our top-level module so that the Consul
  // cluster can join using Atlas. This removes the need to use a "well-known"
  // IP address to join the initial cluster, and it gives us the web interface
  // in Atlas.
  atlas_environment = "${var.atlas_environment}"
  atlas_token       = "${var.atlas_consul_token}"
}

// This will output the address of the first Consul instance where we can access
// the Web UI on port 8500.
output "consul-ui" { value = "${module.consul.ip}:8500/ui" }
