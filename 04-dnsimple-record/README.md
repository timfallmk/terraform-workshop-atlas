Managing DNS
============
This section is designed to showcase Terraform's ability to manage more than
compute resources. This section uses DNSimple to create a DNS record to easily
access our instances.

DNSimple Credentials
--------------------
If you do not have the DNSimple credentials in your terraform.tfvars file,
please see the instructor. Make sure you have set the `dnsimple_subdomain`
variable to something unique in the scope of the classroom!

Record Creation
---------------
Now you can run `terraform plan 04-dnsimple-record`. If Terraform prompts
for input, make sure you entered a default on line 6 for the subdomain. This
value must be unique to this training.

Assuming everything looks correct, you can run the apply by running
`terraform apply 04-dnsimple-record`. This will create the subdomain and
point it at the CNAME of your load balancer on EC2. You will see this as an
output.
