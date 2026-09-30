# AWS Verified Access + IAM Identity Center + Terraform

A complete demo that protects a Python Flask application behind **AWS Verified Access**. Users authenticate with **AWS IAM Identity Center**, and a Cedar policy allows access only to members of the `DevOps-Team` group with a verified email address.

## Architecture

Internet → GoDaddy DNS → AWS Verified Access → IAM Identity Center authentication/authorization → Verified Access endpoint → HTTPS ALB → EC2 Flask application

Terraform creates the VPC, subnets, security groups, EC2 instance, ALB, Verified Access instance/trust provider/group/endpoint, Cedar policy, and Verified Access CloudWatch access logging.

## Important prerequisite

AWS Verified Access with IAM Identity Center requires an **AWS Organizations IAM Identity Center instance**, not a standalone-account IAM Identity Center instance. IAM Identity Center must be enabled in the same AWS Region where the Verified Access trust provider is created.

For this project use `us-west-2` (Oregon).

## 1. AWS Console — IAM Identity Center

1. Select **US West (Oregon) / us-west-2**.
2. Open **IAM Identity Center**.
3. Confirm it is an **AWS Organizations instance**. If the account is not part of an Organization, create/use the Organization management setup first.
4. Go to **Groups → Create group**.
5. Group name: `DevOps-Team`.
6. Go to **Users → Add user**.
7. Username: `sagar.dubey`.
8. Email: `sagar@sagardubey.in` (replace with the real mailbox you control).
9. Enter first/last name as requested by the console.
10. Add the user to `DevOps-Team`.
11. Complete the user setup. IAM Identity Center normally sends the user an activation/setup email rather than having you hard-code an AWS password in Terraform.

Terraform reads the existing `DevOps-Team` group automatically and uses its group ID in the Cedar policy, so you do **not** need to copy the group ID manually.

## 2. AWS Console — ACM certificate

Stay in **us-west-2**.

1. Open **AWS Certificate Manager (ACM)**.
2. Request a **public certificate**.
3. Domain: `project.sagardubey.in`.
4. Validation: **DNS validation**.
5. Create the certificate.
6. ACM will show a DNS CNAME name/value pair.
7. Open GoDaddy → `sagardubey.in` → DNS Management.
8. Add the ACM validation CNAME exactly as ACM shows it.
9. Wait until ACM status becomes **Issued**.
10. Copy the certificate ARN.

Do not use an ACM certificate from another AWS Region for this project. The certificate used here is created in `us-west-2`.

## 3. Clone the project

```bash
git clone https://github.com/<your-username>/aws-verified-access-project.git
cd aws-verified-access-project/terraform
```

If you are using the ZIP instead of Git, extract it and enter the `terraform` directory.

## 4. Create terraform.tfvars

Copy the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Windows PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region                 = "us-west-2"
subdomain                  = "project.sagardubey.in"
acm_certificate_arn        = "arn:aws:acm:us-west-2:123456789012:certificate/REPLACE-ME"
identity_center_group_name = "DevOps-Team"
instance_type              = "t3.micro"
```

Replace only the certificate ARN (and domain/group if you changed them).

**Do not commit `terraform.tfvars`** because it is intentionally ignored by Git.

## 5. AWS CLI credentials

Terraform uses your existing AWS CLI credentials. Verify them before applying:

```bash
aws sts get-caller-identity --region us-west-2
```

If you use a named AWS CLI profile:

```bash
aws sts get-caller-identity --profile <profile-name> --region us-west-2
```

Then either export the profile or configure your normal AWS CLI environment.

## 6. Terraform deployment

From the `terraform` directory:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply -auto-approve
```

The deployment creates:

- VPC + public subnets + Internet Gateway
- Security groups
- Amazon Linux EC2 instance
- Python Flask application
- Application Load Balancer + HTTPS listener
- AWS Verified Access instance
- IAM Identity Center trust provider
- Verified Access group
- Cedar authorization policy
- Verified Access load-balancer endpoint
- CloudWatch Verified Access access logging

## 7. GoDaddy — after Terraform finishes

Terraform prints an output similar to:

```text
verified_access_endpoint_dns = "project-sagardubey....verified-access.us-west-2.amazonaws.com"
```

In GoDaddy DNS Management for `sagardubey.in`, add:

| Field | Value |
|---|---|
| Type | `CNAME` |
| Name / Host | `project` |
| Value / Target | **exact value of `verified_access_endpoint_dns`** |
| TTL | 600 seconds / 10 minutes, or GoDaddy's available short TTL |

Do not paste `https://` into the CNAME target.

## 8. Test

Open:

```text
https://project.sagardubey.in
```

Expected flow:

1. Browser reaches AWS Verified Access.
2. User is sent to IAM Identity Center for authentication.
3. IAM Identity Center returns the user's identity context.
4. Verified Access evaluates the Cedar policy.
5. User is allowed only when they are in `DevOps-Team` and their email is verified.
6. Verified Access proxies the request to the ALB.
7. ALB sends it to the Flask EC2 instance.
8. Flask returns the JSON response.

## 9. Troubleshooting

### `terraform data aws_identitystore_group` fails

Check that IAM Identity Center is enabled in `us-west-2`, that it is an AWS Organizations instance, and that the group is exactly named `DevOps-Team`.

### ACM remains Pending validation

Check that the CNAME name/value from ACM was copied exactly into GoDaddy. Do not accidentally duplicate the domain suffix if GoDaddy automatically appends it.

### Verified Access does not authenticate

Confirm the IAM Identity Center instance and Verified Access trust provider are in the same Region (`us-west-2`).

### ALB target is unhealthy

Use Systems Manager Session Manager to inspect the instance:

```bash
sudo systemctl status verified-access-app
sudo journalctl -u verified-access-app -n 100 --no-pager
curl http://localhost:5000/health
```

The EC2 role includes `AmazonSSMManagedInstanceCore` so Session Manager can be used without opening SSH port 22.

### DNS does not resolve immediately

DNS changes can take some time. Check with:

```bash
nslookup project.sagardubey.in
```

or:

```bash
dig project.sagardubey.in CNAME
```

## 10. Cleanup

When finished, remove the infrastructure to stop ongoing AWS charges:

```bash
cd terraform
terraform destroy
```

The IAM Identity Center user/group and ACM certificate were created outside Terraform, so manage/delete those separately in the AWS Console if you no longer need them.

## Security notes

- EC2 port 5000 accepts traffic only from the ALB security group.
- SSH port 22 is not opened.
- EC2 uses IMDSv2 (`http_tokens = required`).
- The ALB terminates HTTPS using the ACM certificate.
- Verified Access provides the identity-aware front door and Cedar authorization layer.
- The application is intentionally a demo and should be hardened further before production use.

## Cost note

This demo uses billable AWS resources such as an Application Load Balancer, EC2, and Verified Access. Destroy the Terraform stack when you finish testing.
