# Next we are going to create a compute resource ("server") in EC2. There are
# a number of fields that Terraform accepts, but we are only going to use the
# required ones for now.
resource "aws_instance" "web" {
  # This tells Terraform to create 3 of the same instance. Instead of copying
  # and pasting this resource block multiple times, we can easily scale forward
  # and backward with the count parameter. Usually this is left as a variable,
  # but we will hardcode here for simplicity.
  count = 3

  # The ami is the AMI ID (like "ami-dfba9ea8"). Since AMIs are
  # region-specific, we can ask Terraform to look up the proper AMI ID from our
  # variables map in the aws.tf file.
  #
  # Notice that we access variables using the "var" keyword and a "dot"
  # notation. The "lookup" is built into Terraform and provides a way to look
  # up a value in a map.
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # For demonstration purposes, we will launch the smallest instance.
  instance_type = "t2.micro"

  # We could hard-code the key_name to the string "hashicorp-training" from
  # above, but Terraform allows us to reference our key pair resource block.
  # This also declares the AWS keypair as a dependency of the aws_instance
  # resource. Terraform builds a graph of all the resources and executes in
  # parallel where possible. If we just hard-coded the name, it is possible
  # Terraform would create the instance first, then create the key, which
  # would raise an error.
  key_name = "${aws_key_pair.hashicorp-training.key_name}"

  # The subnet_id is the subnet this instance should run in. We can just
  # reference the subnet created by our aws.tf file.
  subnet_id = "${aws_subnet.hashicorp-training.id}"

  # The vpc_security_group_ids specifies the security group(s) this instance
  # belongs to. We can reference the security group created in the aws.tf file.
  # This security group is "wide open" and allows all ingress and egress
  # traffic through.
  vpc_security_group_ids = ["${aws_security_group.hashicorp-training.id}"]

  # Tags are arbitrary key-value pairs that will be displayed with the instance
  # in the EC2 console. "Name" is important since that is what will be
  # displayed in the console.
  tags {
    Name = "web-${count.index}"
  }

  # This tells Terraform how to connect to the instance to provision. Terraform
  # uses "sane defaults", but we are utilizing a custom SSH key, so we need to
  # specify the connection information here.
  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  # The first remote-exec provisioner is used to wait for cloud-init (which is
  # an AWS-EC2-specific thing) to finish. Without this line, Terraform may try
  # to provision the instance before apt has updated all its sources. This is
  # an implementation detail of an operating system and the way it runs on the
  # cloud platform; this is not a Terraform bug.
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/wait-for-ready.sh",
    ]
  }

  # Use the remote-exec provisioner to execute commands to install a simple
  # web server.
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -yqq update",
      "sudo apt-get -yqq install apache2",
      "echo \"<h1>${self.public_dns}</h1>\" | sudo tee /var/www/html/index.html",
      "echo \"<h2>${self.public_ip}</h2>\"  | sudo tee -a /var/www/html/index.html",
    ]
  }
}

# Create a new load balancer
resource "aws_elb" "web" {
  # This is the name of the ELB.
  name = "web"

  # This puts the ELB in the same subnet (and thus VPC) as the instances. This
  # is required so the ELB can forward traffic to the instances.
  subnets = ["${aws_subnet.hashicorp-training.id}"]

  # This specifies the security groups the ELB is a part of.
  security_groups = ["${aws_security_group.hashicorp-training.id}"]

  # This tells the ELB which port(s) to listen on. This block can be specified
  # multiple times to specify multiple ports. We are just using a simple web
  # server, so port 80 is fine.
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # This sets a health check for the ELB. If instances in the ELB are reported
  # as "unhealthy", they will stop receiving traffic. This is a simple HTTP
  # check to each instance on port 80.
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  # This sets the list of EC2 instances that will be part of this load
  # balancer. Take careful note of the "*" parameter. This tells Terraform to
  # use all of the instances created via the increased count above.
  instances = ["${aws_instance.web.*.id}"]

  # This names the ELB.
  tags {
    Name = "hashicorp-training"
  }
}

# This tells terrafrom to export (or output) the AWS load balancer's public
# DNS. It also outputs each instance's IP address for reference.
output "lb-address" {
  value = "${aws_elb.web.dns_name}"
}

output "instance-ips" {
  value = "${join(", ", aws_instance.web.*.public_ip)}"
}
