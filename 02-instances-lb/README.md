AWS Instances and ELB
=====================
This second section will create a cluster of three web servers and one Amazon
Elastic load balancer.

Instance Resources
------------------
If we examine the `main.tf` file, you will notice a series of resources and
provisioners. There are two main blocks - the first is the list of web
instances, and the second is the aws_elb resource. Each instance uses a series
of scripts to do the follow

1. Install the apache webserver
2. Echo some "self" data into the static html file

There are a number of different built-in provisioners in Terraform including
"shell", "Chef", scripts, and more. Please see the Terraform documentation for
more examples.

Instance Creation
-----------------
Let's run the Terraform plan to see the proposed output:

    $ terraform plan 02-instances-lb

Notice that Terraform plans to create four (4) new resources. Assuming
everything looks okay, let's apply this plan:

    $ terraform apply 02-instances-lb

This can take a few minutes, but watching the output can be exciting. If you
get an error, please ask the instructor for help. At the end of the Terraform
run, you should see some output. This is discussed in the next section.

Outputs
-------
You may have noticed "output" as a new keyword in some of the files. There is a
lot of information contained in Terraform's state, and sometimes it is handy to
pull specific pieces out for processing. In addition to being displayed at the
end of a successful Terraform apply, output variables can be accessed via the
command line using the `terraform output` command. For example, the following
command could be used to get the address of the Consul UI:

    $ terraform output instance-ips

Or you could list all outputs:

    $ terraform output

Try to get the output for the `lb-address` on your own.

ELB Pitfalls
------------
One thing you may notice is that the ELB address may not be immediately
accessible via the browser. This is because Amazon's load balancer
implementation relies on DNS. Until the DNS propagates, you cannot receive
traffic. We will remedy this in a later section.
