variable "aws_region" {
  description = "AWS Region for the bastion instance"
  type        = string
}

variable "enabled" {
  description = "Whether or not to create the bastion instance"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Namespace for the bastion instance"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnet IDs available for the bastion"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "tunnel_ports" {
  description = "Ports that the bastion instance should be able to hit for SSH tunneling"
  type        = list(number)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID for the bastion instance"
  type        = string
}
