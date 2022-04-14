resource "aws_security_group" "this" {
  count = var.enabled ? 1 : 0

  name        = "${var.namespace}-bastion"
  description = "Security group that only allows egress"
  tags        = var.tags
  vpc_id      = var.vpc_id
}

locals {
  security_group_id = var.enabled ? aws_security_group.this[0].id : ""
  tunnel_ports      = var.enabled ? [for p in var.tunnel_ports : tostring(p)] : []
}

# The bastion needs outbound 443 to talk to the AWS Session Manager API
resource "aws_security_group_rule" "https" {
  count = var.enabled ? 1 : 0

  security_group_id = local.security_group_id
  type              = "egress"
  protocol          = "tcp"
  to_port           = 443
  from_port         = 443
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# Allow the bastion outbound to the ports where users will be tunneling to
resource "aws_security_group_rule" "tunnel" {
  for_each = toset(local.tunnel_ports)

  security_group_id = local.security_group_id
  type              = "egress"
  protocol          = "tcp"
  to_port           = each.key
  from_port         = each.key
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# See tunnel.sh for an example of port forwarding with this instance
module "ec2_bastion_server" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.0"

  ami_filter             = { "name" : ["amzn2-ami-hvm-*-x86_64-gp2"] }
  ami_owners             = ["amazon"]
  assign_eip_address     = false
  enabled                = var.enabled
  instance_type          = "t2.micro"
  name                   = "bastion"
  namespace              = var.namespace
  security_group_enabled = false
  security_groups        = [local.security_group_id]
  ssm_enabled            = true
  subnets                = var.private_subnet_ids
  tags                   = var.tags
  vpc_id                 = var.vpc_id
}
