variable "atlas_username" {}
variable "atlas_consul_token" {}
variable "atlas_environment" {}

// Pull the web artifact from Atlas
resource "atlas_artifact" "web" {
  name = "${var.atlas_username}/web"
  type = "amazon.ami"
}

// Pull the haproxy artifact from Atlas
resource "atlas_artifact" "haproxy" {
  name = "${var.atlas_username}/haproxy"
  type = "amazon.ami"
}

resource "aws_instance" "web" {
  count = 3

  // Pull the AMI id from the Atlas registry - this is the fully-compiled
  // artifact that has apache, consul, and consul-template already installed.
  ami = "${atlas_artifact.web.metadata_full.region-us-east-1}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.terraform-tutorial.key_name}"
  subnet_id     = "${aws_subnet.terraform-tutorial.id}"

  vpc_security_group_ids = ["${aws_security_group.terraform-tutorial.id}"]

  tags { Name = "web-${count.index}" }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul",
      "echo 'ATLAS_TOKEN=${var.atlas_consul_token}' | sudo tee -a /etc/service/consul",
      "echo 'NODE_NAME=web-${count.index}' | sudo tee -a /etc/service/consul",
      "sudo service consul restart",
    ]
  }
}

resource "aws_instance" "haproxy" {
  // Pull the AMI id from the Atlas registry.
  ami = "${atlas_artifact.haproxy.metadata_full.region-us-east-1}"

  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.terraform-tutorial.key_name}"
  subnet_id     = "${aws_subnet.terraform-tutorial.id}"

  vpc_security_group_ids = ["${aws_security_group.terraform-tutorial.id}"]

  tags { Name = "haproxy" }

  connection {
    user     = "ubuntu"
    key_file = "${path.module}/${var.private_key_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ATLAS_ENVIRONMENT=${var.atlas_environment}' | sudo tee -a /etc/service/consul",
      "echo 'ATLAS_TOKEN=${var.atlas_consul_token}' | sudo tee -a /etc/service/consul",
      "echo 'NODE_NAME=haproxy' | sudo tee -a /etc/service/consul",
      "sudo service consul restart",
    ]
  }
}

// In order to start using this with Atlas, you will need to setup your remote
// state with Atlas. If you are starting a new project, you could just use
// the GitHub integration. Since we have an existing project, we have to
// configure the remote state and push our current Terraform configurations to
// Atlas so that Atlas can manage our resources.

// First, export you Atlas token as an environment variable. Terraform reads
// this environment variable to authenticate you with Atlas:
//
//     $ export ATLAS_TOKEN="..."
//

// The way we send our state to Atlas is via the following commands. Similar to
// git, first we configure the remote:
//
//   $ terraform remote config \
//       -backend="atlas" \
//       -backend-config="name=<username>/training"
//
// Be sure to replace "<username>" with your Atlas username. This will configure
// the remote state. Now we need to push our copy to Atlas:
//
//   $ terraform remote push
//
// Similar to `git push`, this will send our remote state to Atlas. Atlas is now
// managing our remote state - this is most ideal for teams or using Atlas to
// run Terraform for you (which we will do now).
//
// We could connect to GitHub, but since we have our Terraform configurations
// locally, let's just upload them to Atlas now:
//
//   $ terraform push \
//       -vcs=false \
//       -name="<username>/training" \
//       05-atlas/terraform
//
// Be sure to replace "<username>" with your Atlas username (the same you used
// for configuring the remote state).
//
// This will push our local Terraform files to Atlas and trigger a plan. It will
// also push the local variables we have configured (such as our AWS secrets)
// securely to Atlas.
//
// We specify the vcs=false option because we are not using VCS (yet)
//
// Now we can link this environment to GitHub and leverage SCM workflows for our
// infrastructure! Click on "integrations" in the Atlas UI for this environment
// and link to this GitHub repository under the `terraform` subdirectory.
//
