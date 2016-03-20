Consul and Web Cluster
======================
This third section will create our Consul cluster of three nodes, three web
instances, and an haproxy instance to load balance our three instances. Thus we
will have seven (7) total resources.

This section is also designed to showcase Terraform's use of modules. There
already exists a great community module for installing and configuring Consul,
so we will leverage that module.

Consul Module
-------------
Let's take a moment to examine the Consul module in the `consul.tf` file. Notice
that we need to provide very little information to the module in order to gain
its benefits. Next, let's take a look at the actual module on GitHub (note: the
instructor will walk you through the module).

https://github.com/sethvargo/tf-consul-atlas-join

Instance Resources
------------------
If we examine the `main.tf` file, you will notice a series of resources and
provisioners. There are two main blocks - the first is the list of web
instances, and the second is the haproxy instance. They each use a series of
scripts to do the following:

1. Install the Consul Client
2. Install the Consul Template process
3. Install the package (either apache for web or haproxy for the load balancer)
4. Register the service with Consul

On the web nodes, Consul Template is used to render a static HTML file that
reads a key from Consul's key-value store. On the haproxy node, Consul Template
is used to dynamically render the haproxy configuration for the load balancer
configuration.

Instance Creation
-----------------
Let's run the Terraform plan to see the proposed output:

    $ terraform plan 03-consul-haproxy

Notice that Terraform immediately errors about a missing module. This is because
modules are versioned and vendored locally in a `.terraform` directory. We can
fetch the module by running:

    $ terraform get 03-consul-haproxy

Now the module is vendored. Even if the upstream module changes, Terraform will
continue to use our locally cached copy unless we force an update. Now re-run
the plan:

    $ terraform plan 03-consul-haproxy

Assuming everything looks okay, let's apply this plan:

    $ terraform apply 03-consul-haproxy

This can take a few minutes, but watching the output can be exciting. If you
get an error, please ask the instructor for help. At the end of the Terraform
run, you should see some output. This is discussed in the next section.

Once the apply has finished, AWS will have provisioned one new instance and
destroyed the load balancer, but you will notice that the existing instances
are not running Consul. Even though we added information to the provisioner,
Terraform's provisioner is only done during initial instance creation.

Following the immutable infrastructure paradigm, we need to destroy these web
instances and create new ones to provision them (we will move this to build
time steps shortly).

We can tell Terraform to destroy and re-create the instances using the
`terraform taint` command:

    $ terraform taint aws_instance.web.0
    $ terraform taint aws_instance.web.1
    $ terraform taint aws_instance.web.2

Yes, it is a bit annoying that you cannot specify `.web.*`, but this is a
safety feature in Terraform, since tainting is a potentially dangerous
operation.

Note that tainting a resource is a _local_ operation. We have not yet changed
any production resources. If you run `terraform plan 03-consul-haproxy`, you
will see the "-/+", indicating that Terraform is going to destroy and create
new instance. Run `terraform apply 03-consul-haproxy` to destroy and create
these new instances (thus installing Consul)

Now run the plan + apply again and see the instances are destroyed and
re-provisioned.

Playing
-------
Login to Atlas. In the Consul web UI, you can see the list of services, nodes,
health checks, and more. Additionally, you can manage the key-value part of
Consul. Add a new key named "tutorial" and save a value. Then, refresh the
address of your web instance and notice the value has changed!

Depending on time, the instructor may demonstrate how Consul Template is also
dynamically rendering the haproxy configuration to the class.
