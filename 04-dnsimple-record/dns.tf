// You must change this value to a unique subdomain that will not conflict with
// others. Pick your favorite color, favorite vegetable, and a random number
// between 1 and 100. For example, "red-carrot-93".
variable "dnsimple_subdomain" {
  description = "The subdomain for the DNS record on terraform.rocks."
}

// sk your instructor for the correct values.
variable "dnsimple_email" {}
variable "dnsimple_token" {}

// This sets up the credentials for interacting with DNSimple.
provider "dnsimple" {
  email = "${var.dnsimple_email}"
  token = "${var.dnsimple_token}"
}

// This resource will create a new DNS record for the subdomain of your
// choosing from the variable above.
resource "dnsimple_record" "web" {
  domain = "terraform.rocks"
  name   = "${var.dnsimple_subdomain}"
  value  = "${aws_instance.haproxy.public_ip}"
  type   = "A"
  ttl    = 30
}

// This resource will create a new DNS record for consul.your-subdomain so you
// can easily access the Consul instance.
resource "dnsimple_record" "consul" {
  domain = "terraform.rocks"
  name   = "consul.${var.dnsimple_subdomain}"
  value  = "${module.consul.ip}"
  type   = "A"
  ttl    = 30
}

// Output the DNS address so you can easily copy-paste into the browser.
output "web" { value = "${dnsimple_record.web.hostname}" }
output "consul" { value = "${dnsimple_record.consul.hostname}:8500" }

// Now you can run `terraform plan 04-dnsimple-record`. If Terraform prompts
// for input, make sure you entered a default on line 6 for the subdomain. This
// value must be unique to this workshop.

// Assuming everything looks correct, you can run the apply by running
// `terraform apply 04-dnsimple-record`. This will create the subdomain and
// point it at the CNAME of your load balancer on EC2.

// Now visit the URL! :)
