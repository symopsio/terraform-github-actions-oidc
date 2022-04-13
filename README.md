# terraform-github-actions-oidc

This repo is a companion to our blog on setting up a Terraform pipeline with GitHub Actions and GitHub OIDC for AWS.

## Repo layout

### bootstrap environment

The [bootstrap](environments/bootstrap) environment is where we configure the IAM Role that our GitHub action will use.

### prod environment

The [prod](environments/prod) environment is where we set up our Terraform state backend and provision some example infrastructure, in this case an AWS SSM-enabled bastion instance.

### github-oidc-role module

The [github-oidc-role](modules/github-oidc-role) creates the IAM Role that our GitHub action will use. 

### ssm-bastion module

The [ssm-bastion](modules/ssm-bastion) sets up a bastion instance that you can access with [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html).

The module also includes a [`tunnel`](modules/ssm-bastion/tunnel.sh) script you can use to port forward to local host via the bastion.

## About Sym

[Sym](https://www.symops.com) helps developers solve painful access management problems with standard infrastructure tools.

Check out Sym's [GitHub Actions Quickstart](https://github-actions.tutorials.symops.com/) for an example of how to set up a temporary access flow for Okta using GitHub Actions.
