output "application_url" {
  description = "URL to open after the GoDaddy CNAME is created."
  value       = "https://${var.subdomain}"
}

output "verified_access_endpoint_dns" {
  description = "CNAME target to paste into GoDaddy for the host 'project'."
  value       = aws_verifiedaccess_endpoint.this.endpoint_domain
}

output "alb_dns_name" {
  description = "ALB DNS name. Keep this private from end users; Verified Access is the intended entry point."
  value       = aws_lb.app.dns_name
}

output "identity_center_group_id" {
  description = "IAM Identity Center group ID used by the Cedar policy."
  value       = data.aws_identitystore_group.allowed.group_id
}

output "verified_access_instance_id" {
  value = aws_verifiedaccess_instance.this.id
}

output "verified_access_endpoint_id" {
  value = aws_verifiedaccess_endpoint.this.id
}
