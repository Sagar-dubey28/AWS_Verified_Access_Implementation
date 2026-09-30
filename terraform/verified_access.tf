resource "aws_verifiedaccess_trust_provider" "identity_center" {
  policy_reference_name    = "idc"
  trust_provider_type      = "user"
  user_trust_provider_type = "iam-identity-center"
  description              = "IAM Identity Center trust provider for the DevOps demo"

  tags = { Name = "verified-access-idc" }
}

resource "aws_verifiedaccess_instance" "this" {
  description = "Zero-trust access gateway for the Flask demo"
  tags        = { Name = "verified-access-demo-instance" }
}

resource "aws_verifiedaccess_instance_trust_provider_attachment" "identity_center" {
  verifiedaccess_instance_id       = aws_verifiedaccess_instance.this.id
  verifiedaccess_trust_provider_id = aws_verifiedaccess_trust_provider.identity_center.id
}

resource "aws_verifiedaccess_group" "this" {
  verifiedaccess_instance_id = aws_verifiedaccess_instance.this.id

  # Add this explicit dependency:
  depends_on = [
    aws_verifiedaccess_instance_trust_provider_attachment.identity_center
  ]

  description = "Allow only verified IAM Identity Center users in DevOps-Team"

  policy_document = <<-CEDAR
    permit(principal, action, resource)
    when {
      context.idc.groups has "${data.aws_identitystore_group.allowed.group_id}"
      && context.idc.user.email.verified == true
    };
  CEDAR

  tags = { Name = "verified-access-devops-group" }
}

resource "aws_verifiedaccess_endpoint" "this" {
  verified_access_group_id = aws_verifiedaccess_group.this.id
  attachment_type          = "vpc"
  endpoint_type            = "load-balancer"
  endpoint_domain_prefix   = "project-sagardubey"
  application_domain       = var.subdomain
  domain_certificate_arn   = var.acm_certificate_arn
  security_group_ids       = [aws_security_group.verified_access_endpoint.id]

  load_balancer_options {
    load_balancer_arn = aws_lb.app.arn
    port              = 443
    protocol          = "https"
    subnet_ids        = aws_subnet.private[*].id
  }

  tags = { Name = "verified-access-demo-endpoint" }
}

resource "aws_cloudwatch_log_group" "verified_access" {
  name              = "/aws/verifiedaccess/verified-access-demo"
  retention_in_days = 7
}

resource "aws_verifiedaccess_instance_logging_configuration" "this" {
  verifiedaccess_instance_id = aws_verifiedaccess_instance.this.id

  access_logs {
    cloudwatch_logs {
      enabled   = true
      log_group = aws_cloudwatch_log_group.verified_access.id
    }
  }
}
