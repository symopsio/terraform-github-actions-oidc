variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "bootstrap_enabled" {
  description = "Whether to enable permissions to create the bootstrap S3 bucket and Dynamo Table"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub org for the repo with the action that will use this IAM role"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo with the action that will use this IAM role"
  type        = string
}

variable "namespace" {
  description = "Namespace qualifier to use for role and policy resources"
  type        = string
}

variable "tag_condition" {
  description = "Key-value tag condition to add to IAM policies where possible"
  type        = object({ key = string, value = string })
  default     = { key = "vendor", value = "symops.com" }
}
