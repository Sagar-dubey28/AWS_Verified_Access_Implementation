# Implementation Steps — Short Version

## Phase A — Console prerequisites

### A1. IAM Identity Center

Region: **us-west-2**

- IAM Identity Center → confirm AWS Organizations instance
- Groups → Create `DevOps-Team`
- Users → Add `sagar.dubey`
- Use your real email address and complete activation
- Add user to `DevOps-Team`

### A2. ACM

Region: **us-west-2**

- ACM → Request public certificate
- Domain: `project.sagardubey.in`
- Validation: DNS
- Copy ACM CNAME Name + Value
- GoDaddy DNS → add that CNAME
- Wait for `Issued`
- Copy certificate ARN

## Phase B — Terraform

```bash
git clone https://github.com/<your-username>/aws-verified-access-project.git
cd aws-verified-access-project/terraform
cp terraform.tfvars.example terraform.tfvars
```

Put the ACM ARN in `terraform.tfvars`.

```bash
aws sts get-caller-identity --region us-west-2
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply -auto-approve
```

## Phase C — GoDaddy application DNS

After apply:

```text
verified_access_endpoint_dns = "...verified-access.us-west-2.amazonaws.com"
```

GoDaddy → `sagardubey.in` → DNS:

```text
Type:   CNAME
Name:   project
Value:  <verified_access_endpoint_dns output>
TTL:    600 seconds / short TTL
```

Then open:

```text
https://project.sagardubey.in
```

## Phase D — Login

Use the IAM Identity Center user created in Phase A.

Only the `DevOps-Team` group is permitted by the Cedar policy.

## Phase E — Destroy

```bash
terraform destroy
```
