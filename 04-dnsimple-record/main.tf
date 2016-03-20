variable "atlas_username" {}
variable "atlas_consul_token" {}
variable "atlas_environment" {}

resource "aws_instance" "web" {
  count = 3
  ami   = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.hashicorp-training.key_name}"
  subnet_id     = "${aws_subnet.hashicorp-training.id}"

  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  tags { Name = "web-${count.index}" }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/wait-for-ready.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get --yes install apache2",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul.conf"
    destination = "/tmp/consul.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/web.json"
    destination = "/tmp/web.json"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul",
      "echo 'ATLAS_TOKEN=${var.atlas_consul_token}' | sudo tee -a /etc/service/consul",
      "echo 'NODE_NAME=web-${count.index}' | sudo tee -a /etc/service/consul",
      "sudo service consul restart",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/index.html.ctmpl"
    destination = "/tmp/index.html.ctmpl"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul-template-apache.conf"
    destination = "/tmp/consul-template.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul-template.sh"
    ]
  }
}

resource "aws_instance" "haproxy" {
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.hashicorp-training.key_name}"
  subnet_id     = "${aws_subnet.hashicorp-training.id}"

  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  tags { Name = "haproxy" }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/wait-for-ready.sh"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul.conf"
    destination = "/tmp/consul.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy.json"
    destination = "/tmp/haproxy.json"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul.sh",
      "${path.module}/scripts/install-haproxy.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul",
      "echo 'ATLAS_TOKEN=${var.atlas_consul_token}' | sudo tee -a /etc/service/consul",
      "echo 'NODE_NAME=haproxy' | sudo tee -a /etc/service/consul",
      "sudo service consul restart",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy.cfg.ctmpl"
    destination = "/tmp/haproxy.cfg.ctmpl"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/consul-template-haproxy.conf"
    destination = "/tmp/consul-template.conf"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install-consul-template.sh"
    ]
  }
}
