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

  provisioner "file" {
    source      = "${path.module}/scripts/web/index.html.ctmpl"
    destination = "/tmp/index.html.ctmpl"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/wait-for-ready.sh",
      "${path.module}/scripts/consul-client/install.sh",
      "${path.module}/scripts/consul-template/install.sh",
      "${path.module}/scripts/web/install.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'ATLAS_TOKEN=${var.atlas_token}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'NODE_NAME=web-${count.index}' | sudo tee -a /etc/service/consul &>/dev/null",
      "sudo service consul restart",
    ]
  }
}

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

  provisioner "file" {
    source      = "${path.module}/scripts/lb/haproxy.cfg.ctmpl"
    destination = "/tmp/haproxy.cfg.ctmpl"
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/wait-for-ready.sh",
      "${path.module}/scripts/consul-client/install.sh",
      "${path.module}/scripts/consul-template/install.sh",
      "${path.module}/scripts/lb/install.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'ATLAS_TOKEN=${var.atlas_token}' | sudo tee -a /etc/service/consul &>/dev/null",
      "echo 'NODE_NAME=haproxy' | sudo tee -a /etc/service/consul &>/dev/null",
      "sudo service consul restart",
    ]
  }
}
