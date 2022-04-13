output "this_role_arn" {
  description = "The ARN of the GitHub Actions IAM Role"
  value       = module.github_oidc_role.this_role_arn
}
