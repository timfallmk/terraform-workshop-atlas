# Here we are defining some new variables. These variables' values come from
# the terraform.tfvars value we filled out at the start of training.
variable "atlas_username" {}
variable "atlas_token" {}
variable "atlas_environment" {}

resource "aws_instance" "web" {
  count = 3
  ami   = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.hashicorp-training.key_name}"
  subnet_id     = "${aws_subnet.hashicorp-training.id}"

  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  tags {
    Name = "web-${count.index}"
  }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  # Add our Consul Template input template - this will be used to render our
  # dynamic HTML page for apache.
  provisioner "file" {
    source      = "${path.module}/scripts/web/index.html.ctmpl"
    destination = "/tmp/index.html.ctmpl"
  }

  provisioner "remote-exec" {
    scripts = [
      # The first remote-exec provisioner is used to wait for cloud-init (which
      # is an AWS-EC2-specific thing) to finish. Without this line, Terraform
      # may try to provision the instance before apt has updated all its
      # sources. This is an implementation detail of an operating system and
      # the way it runs on the cloud platform; this is not a Terraform bug.
      "${path.module}/scripts/wait-for-ready.sh",

      # First we will install the Consul client.
      "${path.module}/scripts/consul-client/install.sh",

      # Install Consul Template, which will be used to render our dynamic
      # index.html pages.
      "${path.module}/scripts/consul-template/install.sh",

      # Next, install our webserver, apache.
      "${path.module}/scripts/web/install.sh",
    ]
  }

  # Lastly, export our Consul configuration. This is the "runtime"
  # configuration piece.
  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'ATLAS_TOKEN=${var.atlas_token}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'NODE_NAME=web-${count.index}' | sudo tee -a /etc/service/consul &>/dev/null",
      "sudo service consul restart",
    ]
  }
}

# This is replacing the ELB from 04-load-balancer. Instead of using Amazon's
# load balancer, we will use our own. Most of these attributes should already
# be familiar to you, so we will skip down to the provisioner.
resource "aws_instance" "haproxy" {
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.hashicorp-training.key_name}"
  subnet_id     = "${aws_subnet.hashicorp-training.id}"

  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  tags {
    Name = "haproxy"
  }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  # Add our Consul Template input template - this will be used to dynamically
  # configure haproxy.
  provisioner "file" {
    source      = "${path.module}/scripts/lb/haproxy.cfg.ctmpl"
    destination = "/tmp/haproxy.cfg.ctmpl"
  }

  provisioner "remote-exec" {
    scripts = [
      # Same wait for ready script.
      "${path.module}/scripts/wait-for-ready.sh",

      # First we will install the Consul client.
      "${path.module}/scripts/consul-client/install.sh",

      # Install Consul Template, which will be used to render our dynamic
      # haproxy configuration.
      "${path.module}/scripts/consul-template/install.sh",

      # Next, install our loadbalancer, haproxy.
      "${path.module}/scripts/lb/install.sh",
    ]
  }

  # This is the same runtime configuration as above.
  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'ATLAS_TOKEN=${var.atlas_token}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'NODE_NAME=haproxy' | sudo tee -a /etc/service/consul &>/dev/null",
      "sudo service consul restart",
    ]
  }
}

# This is the address of the ELB.
output "lb-address" {
  value = "${aws_instance.haproxy.public_dns}"
}
