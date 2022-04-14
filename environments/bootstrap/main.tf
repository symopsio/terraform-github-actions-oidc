provider "aws" {
  region = var.aws_region
}

module "github_oidc_role" {
  source = "../../modules/github-oidc-role"

  aws_region    = var.aws_region
  github_org    = var.github_org
  github_repo   = var.github_repo
  namespace     = var.namespace
  tag_condition = var.tag_condition
}
