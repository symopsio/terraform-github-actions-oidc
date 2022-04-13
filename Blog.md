# Set up a Terraform Pipeline with GitHub Actions and GitHub OIDC for AWS

At [Sym](https://www.symops.com) we often work with customers that run Terraform pipelines but don't use Terraform Cloud for their backend state storage. To help these teams out, we've developed some patterns to quickly bootstrap an S3-backed Terraform pipeline with a few GitHub Actions. We also take advantage of GitHub's OIDC support for AWS to make this setup as frictionless as possible.

## Example walkthrough

We're going to walk through an example that sets up AWS infrastructure using our GitHub Actions approach. The example provisions an EC2 instance that you can SSH into with [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), along with bootstrapping the Terraform state for ths resource.

## Building on the community

Our example builds on many enabling technologies and resources from the community... I'm going to highlight a few of them here.

### GitHub OIDC for AWS

We're going to get this whole setup configured without ever putting an AWS Access Key and Secret Key ID in GitHub! We can do this thanks to GitHub Actions' support for [OpenID Connect (OIDC)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers). With OIDC, we can provision an AWS IAM Role that trusts our GitHub org and repo. We then use the [configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials) Action to create role-based temporary access keys that Terraform can use to do the things.

### GitHub Actions Permissions

Using GitHub OIDC means you'll have to do some permissions configuration in your GitHub Action configs. If your organization is set up to allow [permissive default access](https://docs.github.com/en/github-ae@latest/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token), then you may not have encountered the GitHub permissions configuration requirements before. GitHub OIDC requires `write` for the `id-token` scope, which is not in the default access scopes. The tricky thing is that once you configure any permissions, all the ones you don't specify are set to no access. So you have to configure all the ones you need. Since our workflow [configs](.github/workflows) are going to create and comment on pull requests, we've added the `contents`, `issues`, and `pull-requests` scopes in addition to the `id-token` scope.

### terraform-aws-oidc-github module

Getting your OIDC stuff set up is pretty simple, but rather than starting from scratch there's a nice starter module by [@unfunco](https://github.com/unfunco/terraform-aws-oidc-github) that we're going to use. The module lets you configure the name of the GitHub org and the list of GitHub repositories that your AWS Role should trust.

Note that you can actually lock down the trust relationship to more fine grained conditions than the `terraform-aws-oidc-github` module currently exposes. You can filter for specific environments, for pull requests only, for specific branches, or specific tags (full details [here](https://docs.github.com/en/enterprise-cloud@latest/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims). We're going to contribute an example with all the knobs and levers soon!

### tfstate-backend module

We're not just going to avoid setting AWS Access Keys for our pipeline, we're also going to bootstrap our own Terraform state backend right from within GitHub Actions! The [`tfstate-backend`](https://registry.terraform.io/modules/cloudposse/tfstate-backend/aws/latest) module by [CloudPosse](https://cloudposse.com) sets up an S3 bucket and a DynamoDB table to manage concurrent state locks. Critically for our setup with GitHub Actions, the module generates a `backend.tf` config file that we can use to automatically bootstrap state management from a GitHub Action.

### setup-terraform Action

We use HashiCorp's [`setup-terraform`](https://github.com/hashicorp/setup-terraform) module in our workflows to actually do the provisioning. The `README` provides a nice example of how to comment on your pull requests with a well formatted Terraform plan.

## Step 1: Provision the IAM Roles that our workflows will use

Setting up GitHub Actions so that we can use IAM Roles instead of access keys is awesome! But now we have to actually give the roles some permissions so that they can actually manage our infrastructure. We've created a bootstrap configuration in our example repo that sets up an IAM that can bootstrap state and provision our EC2 instance.

This is the only step we'll have to do from outside of GitHub Actions, since we need these roles to exist in order for your workflows to run. We'll take the role outputs from our bootstrap configuration and use those to configure our workflows in the next step.

```
$ cd environments/bootstrap
$ terraform apply
```

We split the IAM Permissions into two policies - a `bootstrap` policy that you only need during state management bootstrap and a `main` policy that you need for ongoing iteration on your infrastructure. In further iterations of this setup, your org could maintain a general purpose bootstrap role to let teams create state management resources.

## Step 2: Bootstrap Terraform State

Now that we've got a bootstrap role provisioned, we can set the `AWS_ROLE_ARN` in the [`terraform-bootstrap`](.github/workflows/terraform-bootstrap.yaml) workflow. `terraform-bootstrap` provisions the `tfstate-backend` module where we'll store our Terraform state, and creates a Pull Request that adds backend configuration to our repo. `terraform-bootsrap` is set up with the [`workflow_dispatch`](https://github.blog/changelog/2020-07-06-github-actions-manual-triggers-with-workflow_dispatch/) trigger - this means we can manually trigger the workflow from the UI rather than it being triggered by Git activity.

Manually running the workflow will provision your state and create a pull request that looks like the following:

## Step 3: Provision Our Infrastructure

Once we've got state management configured, we configure the `AWS_ROLE_ARN` in the [`main`](.github/workflows/main.yaml) workflow. The `main` workflow uses one of the recommendations from the [setup-terraform](https://github.com/hashicorp/setup-terraform) action to add comments to Pull Requests. Now whenever we create a Pull Request, our `main` workflow will generate a plan and create a comment in our repo with the results. When we push to `main`, our action will apply the changes to our infrastructure.

## Testing it out

Once you've updated your GitHub Action workflow configs and pushed to `main`, you should have a VPC with an EC2 instance that you can access via AWS Session Manager. Review your GitHub Action output to find the ID of the instance, and then run `aws ssm start-session --target <instance-id>` to connect.

If you configure the `bastion_tunnel_ports` variable, you can use the [`tunnel.sh`](modules/ssm-bastion/tunnel.sh) script to port forward resources to localhost.

## Cleaning up the repo

If you want to clean up this repo when you're done, you have to do a little Terraform dance which we have NOT set up as a GitHub Action. Basically you first have to unconfigure the remote backend state, and THEN do a Terraform destroy. Details in the [`tfstate-backend README`](https://github.com/cloudposse/terraform-aws-tfstate-backend#destroy)

## Next steps

One of the challenges with this workflow is defining what permissions your Main role needs in order to provision your infrastructure. At Sym we're working on ways to make this easier to manage!

We'd also like to explore further constraints on the bootstrap IAM permissions, in particular [session tagging](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html) to limit when the `Create*` actions can run.

## More about Sym

Sym helps developers solve painful access management problems with standard infrastructure tools.

Check out Sym's [GitHub Actions Quickstart](https://github-actions.tutorials.symops.com/) for an example of how to set up a temporary access flow for Okta using GitHub Actions.
