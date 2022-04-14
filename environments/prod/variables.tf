variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "bastion_enabled" {
  description = "Whether or not to create the VPC and bastion instance"
  type        = bool
  default     = false
}

variable "bastion_private_subnet_ids" {
  description = "Subnet IDs available for the bastion"
  type        = list(string)
}

variable "bastion_tunnel_ports" {
  description = "Ports that the bastion instance should be able to hit for SSH tunneling"
  type        = list(number)
  default     = []
}

variable "bastion_vpc_id" {
  description = "VPC ID for the bastion instance"
  type        = string
}

variable "namespace" {
  description = "Namespace for the bastion instance"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
