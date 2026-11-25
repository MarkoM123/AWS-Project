# Security policy and controls

## Scope and threat model

This repository defines a small AWS lab with one public Nginx EC2 instance and one private Python EC2 instance. The assumed threats include internet scanning and exploitation of the public web tier, compromise of the web tier followed by lateral access, misuse of the Terraform provisioning identity, accidental credential/state disclosure, and loss of visibility after a host or IAM event.

This is a source-level assessment. No AWS account was queried, no live configuration was verified, and Terraform was not applied. The infrastructure is not certified against CIS or AWS Well-Architected controls.

## Implemented controls

- Separate public and private subnets, with only the public route table connected to the Internet Gateway.
- Public web ingress is TCP 443 only. The private app accepts TCP 8080 from the web security group reference, with no public address and no SSH/RDP ingress.
- Web egress is explicitly limited to TCP 443 to the regional AWS-managed S3 prefix list and TCP 8080 to the app security group. The app has no configured egress rules.
- The public route table uses an S3 Gateway VPC endpoint. Its endpoint policy permits only `s3:GetObject` on object ARNs in the regional AL2023 repository bucket (`al2023-repos-<region>-de612dc2/*`). This endpoint policy is an additional filter; it does not grant IAM permissions.
- The VPC default security group has no ingress or egress rules; both EC2 instances use the dedicated web/app groups.
- IMDSv2 is required on both EC2 instances; root EBS volumes are encrypted.
- The app systemd service runs as a dedicated non-login user with a read-only filesystem and privilege-escalation restrictions.
- Nginx uses TLS 1.2/1.3, suppresses the version token and adds basic content-type, framing and referrer headers.
- The app address passed to Nginx is read from the Terraform-created app instance rather than a hardcoded IP.
- The Terraform policy's `iam:PassRole` resource uses the active admin account ID and is restricted to `ec2.amazonaws.com`. CloudWatch alarm writes are scoped to this account's `terraform-lab-*` alarm ARNs.
- CI uses no AWS credentials and runs validation/scanning only. GitHub token permission is read-only.

## IAM

The EC2 runtime role is attached to `AmazonSSMManagedInstanceCore` and shared by both instances. Static AWS credentials are not configured on the instances. However, this does not prove that either instance is online in Systems Manager: private app egress is absent, and web registration has not been checked.

The Terraform provisioning policy still grants many EC2 create, update, delete and describe actions against `*`, with an `aws:RequestedRegion` restriction. EC2 `Describe*` operations commonly require `Resource = "*"`; many write operations do not. Narrowing all write operations requires checking each action's supported resource types, Terraform create/delete graph and the real plan. Do not remove actions without a permission test in a non-production account. The policy also attaches to a named IAM user, so long-lived user keys remain a deployment-model risk if they are used outside this repository.

## Network and workload security

The private subnet has only the local VPC route. The public web instance can reach the regional AL2023 package repository through the S3 Gateway endpoint and S3 prefix-list egress rule. Other outbound HTTPS destinations are blocked; the Internet Gateway default route does not override the more-specific S3 endpoint route, and the web security group denies other outbound HTTPS. The app has no internet route. No custom Network ACL is defined, so AWS's default network ACL applies; it is not an additional restrictive control here. Security groups are stateful, so responses to inbound client HTTPS connections require no separate outbound internet rule.

The web certificate is self-signed and generated at boot. TLS encryption is present, but clients cannot authenticate the public endpoint through a trusted CA. There is no HTTP listener or redirect because port 80 is not exposed. The Python service is a minimal demonstration server, not a production application server.

## Encryption and secrets

EBS root volumes are encrypted. No S3 backend, KMS key, Secrets Manager or Parameter Store resource is configured. Terraform uses local state, which may contain infrastructure details and must be protected, backed up securely and excluded from Git. No secret values should be placed in Terraform variables, user data, outputs or CI logs.

## Logging and response

The repository creates CPU and EC2 status-check alarms. It does not configure alarm actions, CloudWatch Logs ingestion, CloudTrail, GuardDuty or AWS Config. Instance user-data logs and system logs remain on the instances unless an operator retrieves them. There is no alert recipient or incident-response automation configured.

For an incident, preserve Terraform state and relevant host/CloudTrail logs, rotate affected IAM credentials, isolate compromised instances with security-group or subnet changes, and record actions. A real response procedure needs an owner, contact path and account-specific runbook.

## Vulnerability management

The GitHub Actions workflow runs Terraform formatting/validation, TFLint, Checkov, Trivy IaC configuration scanning and Gitleaks history scanning. It does not authenticate to AWS, generate a Terraform plan, apply changes, or deploy resources. Review scanner findings in context; document narrowly justified exceptions instead of suppressing whole rule families.

Report suspected vulnerabilities privately through the repository owner's preferred contact channel. Do not open a public issue containing credentials or exploitable details.
