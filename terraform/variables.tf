variable "aws_region" {
  description = "AWS region. IAM Identity Center must be enabled in this same region for Verified Access."
  type        = string
  default     = "us-west-2"
}

variable "subdomain" {
  description = "Public application hostname. ACM certificate must cover this exact hostname."
  type        = string
  default     = "project.sagardubey.in"
}

variable "acm_certificate_arn" {
  description = "Issued ACM public certificate ARN for the application hostname."
  type        = string
}

variable "identity_center_group_name" {
  description = "Existing IAM Identity Center group allowed to access the application."
  type        = string
  default     = "DevOps-Team"
}

variable "alert_email" {
  description = "Email address for the optional CloudWatch alarm notification."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for the Flask demo."
  type        = string
  default     = "t3.micro"
}
