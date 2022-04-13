output "bastion_instance_id" {
  description = "The instance id of the bastion"
  value       = var.bastion_enabled ? module.ssm_bastion.instance_id : ""
}

output "state_bucket_arn" {
  description = "The Terraform state bucket where this configuration is stored"
  value       = module.remote_state.s3_bucket_arn
}
