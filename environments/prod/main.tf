provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Our bootstrap action does the right steps to initialize backend state with
# this module.
module "remote_state" {
  source  = "cloudposse/tfstate-backend/aws"
  version = "= 0.38.1"

  namespace  = var.namespace
  name       = "tfstate"
  attributes = [data.aws_caller_identity.current.account_id]

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  terraform_state_file               = "prod/terraform.tfstate"
  force_destroy                      = false
}

module "ssm_bastion" {
  source = "../../modules/ssm-bastion"

  aws_region         = var.aws_region
  enabled            = var.bastion_enabled
  namespace          = var.namespace
  private_subnet_ids = var.bastion_private_subnet_ids
  tags               = var.tags
  tunnel_ports       = var.bastion_tunnel_ports
  vpc_id             = var.bastion_vpc_id
}
