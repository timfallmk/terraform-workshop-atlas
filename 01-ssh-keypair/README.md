Initial Infrastructure
======================
This first module is designed to get your familiar with the Terraform syntax,
command line, and recommended workflow. We will create a few resources in AWS
and then explore various scenarios to get us thinking critically about how
Terraform manages resources.

Virtual Machine
---------------
This training runs in a virtual machine driven by Vagrant. Start the VM by
running:

    $ vagrant up

And then establish a shell to the machine by running:

    $ vagrant ssh

Change directory into the `/vagrant` directory to get started:

    $ cd /vagrant

Planning
--------
The first phase of any Terraform process should be the "plan". Terraform plans
are no-op runs that sync the state with the remote(s) and output a list of
changes that will occur when applied. Plans can optionally be saved to an
executable file to guarantee the contents of the apply will exactly match the
plan. Run the following command:

    $ terraform plan 01-ssh-keypair

Notice that Terraform prompted for credentials? This is because Terraform is
unable to communicate with AWS without providing our credentials. Let's fill
those in now.

Variables
---------
There are a number of ways to set variables in Terraform including environment
variables, special environment variables, via the command line, and via a
tfvars file. For the purposes of this training, we will use a tfvars file,
however, it is recommended that you only use this method if you are comfortable
having plain-text secrets stored with your repository. For more information on
the different types of variables, please see the Terraform documentation.

Open the `terraform.tfvars` file located in the root of this repository and
complete all fields. If you need help, ask your instructor. The resulting file
should look something like this:

```
aws_access_key     = "AKW...."
aws_secret_key     = "2u02ak..."
atlas_token        = "...atlas.v1..."
atlas_username     = "sethvargo"
atlas_environment  = "sethvargo/training"
dnsimple_email     = "sethvargo+terraform@gmail.com"
dnsimple_token     = ""
dnsimple_subdomain = ""
```

Your values may differ slightly. It is important that the `atlas_username` is
included as the first part of the `atlas_environment` slug.

Now that we have filled out the contents of the tfvars file, let's run the plan
again.

    $ terraform plan 01-ssh-keypair

You will notice Terraform uses the "+" to denote a new resource being added.
Terraform will similarly use a "-" to denote a resource that will be removed,
and a "~" to indicate a resource that will have changed attributes in place.

Applying
--------
As mentioned before, a Terraform plan is a no-op and never changes live
infrastructure. The Terraform apply is the process by which infrastructure is
changed and managed. Let's run the apply now:

    $ terraform apply 01-ssh-keypair

This operation should be fairly quick since we are only creating a few
resources.

If you open the Amazon console and look under EC2 -> Key Pairs, you will see
a new keypair has been created named "hashicorp-training". We will use this
keypair to connect to new EC2 instances created on Amazon in the next parts
of this tutorial.

Let's see what happens if we run the plan again:

    $ terraform plan 01-ssh-keypair

You will notice that the output indicates no resources are to change. To further
illustrate the power of Terraform, run `terraform apply 01-ssh-keypair` again.
Terraform will refresh the remote state (more on this later), and then 0
resources will be changed. Terraform is intelligent enough to maintain and
manage state.

Critical Thinking
-----------------
What will happen if we delete this keypair from EC2 outside of Terraform (via
the web interface)? Will Terraform re-create it? Will Terraform throw an error?
Will Terraform ignore it?

Go into the Amazon Key Pair page in the AWS Console and delete the key using
the Web UI. Back on your local terminal, run `terraform plan 01-ssh-keypair`.
Viola! Terraform has intelligently detected that the keypair was removed
out-of-band and re-created it for us.
