// This is the same Consul module as from 05-consul-cluster.
module "consul" {
  source = "github.com/sethvargo/tf-consul-atlas-join"

  ami     = "${lookup(var.aws_amis, var.aws_region)}"
  servers = 3

  subnet_id      = "${aws_subnet.terraform-tutorial.id}"
  security_group = "${aws_security_group.terraform-tutorial.id}"

  key_name         = "${aws_key_pair.terraform-tutorial.key_name}"
  private_key_path = "${path.module}/${var.private_key_path}"

  atlas_environment = "${var.atlas_environment}"
  atlas_token       = "${var.atlas_consul_token}"
}
