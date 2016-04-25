# You must change this value to a unique subdomain that will not conflict with
# others. Pick your favorite color, favorite vegetable, and a random number
# between 1 and 100. For example, "red-carrot-93".
variable "dnsimple_subdomain" {
  description = "The subdomain for the DNS record on terraform.rocks."
}

# Ask your instructor for the correct values.
variable "dnsimple_email" {}
variable "dnsimple_token" {}

# This sets up the credentials for interacting with DNSimple.
provider "dnsimple" {
  email = "${var.dnsimple_email}"
  token = "${var.dnsimple_token}"
}

# This resource will create a new DNS record for the subdomain of your
# choosing from the variable above.
resource "dnsimple_record" "web" {
  domain = "terraform.rocks"
  name   = "${var.dnsimple_subdomain}"
  value  = "${aws_instance.haproxy.public_ip}"
  type   = "A"
  ttl    = 30
}

# Output the DNS address so you can easily copy-paste into the browser.
output "address" {
  value = "${dnsimple_record.web.hostname}"
}
