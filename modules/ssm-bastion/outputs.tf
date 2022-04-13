output "instance_id" {
  description = "Bastion instance ID"
  value       = var.enabled ? module.ec2_bastion_server.instance_id : ""
}
