# Security assessment

## Scope and method

This review examined the repository source on `fix/terraform-review`, including Terraform root files and modules, provider settings, IAM policy, EC2 user data, security groups, CloudWatch alarms, workflow, ignore rules and README. It did not inspect AWS live state, Terraform state, account activity, deployed AMIs, actual billing or SSM registration. Findings are mapped to AWS Well-Architected Security Pillar themes, CIS AWS Foundations principles and Terraform/IaC practices as engineering guidance; this is not a formal benchmark certification.

Severity describes source-level risk in this lab. Cost is incremental AWS cost if a recommendation adds services; implementation effort is relative; compatibility notes identify material changes to the existing deployment.

## Ten highest-priority improvements

| Rank | Severity | Finding and risk | Recommended action | AWS cost | Effort / compatibility |
|---:|---|---|---|---|---|
| 1 | Critical (Trivy) | Web-tier TCP 443 egress is allowed to every IPv4 destination. A compromised host can send traffic over arbitrary HTTPS; the rule also supports package bootstrap and potential SSM access. | Remaining: replace general egress with a controlled package/management path. Do not remove it before choosing an alternative because web bootstrap/management may stop working. | Endpoints or proxy infrastructure incur cost | Medium; restrictive egress can break package updates and management. |
| 2 | High | The CI workflow used long-lived AWS access-key secrets, then ran `terraform plan` on PR code. A change to Terraform, provider configuration or an external data source could execute with those credentials. | Implemented: CI now has read-only GitHub permission, no AWS credentials, no plan/apply, and runs static validation/scans only. Use OIDC with narrowly scoped trust only in a separately authorized deployment workflow. | None | Low; PRs no longer receive AWS-backed plans. |
| 3 | High | The Terraform provisioning policy grants many EC2 lifecycle actions on `*`; compromised credentials could affect unrelated EC2 resources in `eu-north-1`. | Plan-backed IAM action/resource analysis; constrain resources and tag/region conditions where every lifecycle API supports them. Preserve unavoidable `Describe*` wildcard-resource permissions. | None | High; can block Terraform if an API's dependent resource permissions are missed. |
| 4 | High | Python app systemd service ran as root. A remotely reachable app flaw could become host-level root execution. | Implemented: dedicated non-login service user, owned app files, read-only filesystem, and systemd privilege/kernel restrictions. | None | Low; check service startup and log behavior on the next controlled deployment. |
| 5 | High | No durable CloudTrail trail or S3 delivery is declared by this stack. The account may still have CloudTrail Event history or an organization trail; neither was inspected. | Evaluate an organization/account trail, multi-region management events, integrity validation and protected retention. Do not add data events by default. | S3 storage/requests and possibly CloudTrail charges depending on trail/event delivery and account usage | Medium; creates bucket/trail and needs IAM/S3 policy review. |
| 6 | Medium | CloudWatch has CPU/status metrics only. It cannot show app or Nginx request/error logs; alarms have no notification actions. | Add CloudWatch Agent log shipping and a notification target only after deciding network path, retention and alert recipient. | Log ingestion/storage, possible interface endpoints or NAT | Medium; private app needs a route to CloudWatch Logs. |
| 7 | Medium | The public endpoint uses an ephemeral self-signed certificate, so clients cannot validate server identity. | For production, use DNS plus ACM on a managed TLS endpoint (typically ALB) or another trusted certificate lifecycle. | DNS/ALB and public IPv4/service costs if ALB is selected | High; architecture and routing change, not applied to this lab. |
| 8 | Medium | Private app subnet has no route to SSM or package repositories. The SSM policy alone does not establish management connectivity. | Keep fully isolated, or evaluate SSM interface endpoints (ssm, ssmmessages, and region/agent requirements) against NAT and controlled egress options. | Interface endpoints billed per AZ/hour and data; NAT Gateway has hourly and data charges | Medium; improves management but changes network and may incur recurring cost. |
| 9 | Medium | Terraform state is local, with no backend encryption/locking/versioning or centralized access controls. | Protect local state now. Separately plan a remote S3 backend with encryption, versioning, public-access block, least-privilege access, state locking and a backed-up state migration. | S3 storage/requests; optional KMS key cost | High; state migration can break deployments if done incorrectly; do not change automatically. |
| 10 | Medium | Both tiers are in one AZ and the web tier is a directly reachable EC2 public endpoint. An AZ or instance failure takes down the service. | For a production availability target, add a second AZ and a managed ingress/failover design; consider WAF only where threat/risk requires it. | Additional EC2/subnet, load balancer, data processing and optional WAF costs | High; substantial architectural change. |

The Trivy IaC scan confirms the broad web egress rule as Critical. This is a source-level finding, not a live AWS assessment.

## Implemented changes

### CI no longer has AWS access

**Before:** GitHub Actions read long-lived AWS access-key secrets and ran a Terraform plan on pull-request code. Fork PRs also had inconsistent behavior because secrets are withheld, while same-repository code could execute provider/data-source logic with AWS credentials.

**After:** The workflow does not configure AWS credentials or run a plan. It initializes with `-backend=false`, formats, validates, lints, and runs Checkov, Trivy and Gitleaks. Workflow permissions are `contents: read`; action references are pinned to commit SHAs where actions are used. This removes CI's AWS credential exposure path and avoids requiring a live account for validation. It cannot verify AWS API permissions or planned resource changes.

### IAM account and CloudWatch scope

The hardcoded account ID in `iam:PassRole` was replaced with `aws_caller_identity` from the admin provider. The pass role remains limited to the single EC2 role and `iam:PassedToService = ec2.amazonaws.com`. CloudWatch create/delete/describe/tag operations are restricted to alarm ARNs prefixed `terraform-lab-` in `eu-north-1`. AWS's service authorization reference supports alarm-level scoping for these actions. This avoids changing the broad EC2 lifecycle policy without an action-by-action permission test.

The stricter CloudWatch scope requires future alarms managed by this Terraform identity to retain the `terraform-lab-` prefix. If Terraform creates alarms under a different name, permission will be denied until the policy is deliberately updated.

The VPC default security group now has empty ingress and egress rule sets. The declared EC2 instances use their dedicated groups, so this removes default-group lateral access without changing their traffic paths. If a future workload intentionally uses the default group, it will have no network connectivity until explicit rules are designed.

### App process and web server

The Python service now runs as `terraform-app`, a non-login system user, and its files are not writable by the service account's group/others. systemd uses `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`, `ProtectHome`, and kernel/control-group protections. This limits filesystem and privilege impact if the demo service is exploited.

Nginx is restricted to TLS 1.2/1.3, hides its version token, and emits `X-Content-Type-Options`, `X-Frame-Options`, and `Referrer-Policy`. The generated private key is created under restrictive umask and explicitly set to mode 0600. HSTS and CSP are not added: the certificate is self-signed and the service's content contract may change. A trusted certificate and DNS must precede HSTS.

## Area-by-area assessment

### Network security

The public/private route separation is real in Terraform: only the public route table has `0.0.0.0/0` to the Internet Gateway. The app has no public IP. Security-group references enforce web-to-app TCP 8080 and prevent direct app ingress. There is no SSH/RDP rule. The root security-group resource uses dedicated ingress/egress rule resources; web egress is explicit and app egress is not configured. The VPC default security group is explicitly emptied and unused by either instance. No custom NACL exists; the AWS default ACL is used. There is no NAT or VPC endpoint.

The public instance has an internet route and an all-destination TCP 443 egress rule. This is needed by current package installation/bootstrap behavior but is not an egress allowlist. The public TLS certificate is self-signed. A direct public EC2 address has no load-balancer health check, WAF layer or managed certificate integration. Subnet-wide public IPv4 auto-assignment is disabled; only the web instance explicitly requests a public address.

### IAM

The instance role trust policy trusts only `ec2.amazonaws.com`; both instances share `AmazonSSMManagedInstanceCore`. There are no static AWS keys in user data. The Terraform provisioning identity's EC2 policy is materially broad. Many EC2 APIs need multiple resource ARNs or `*`, so replacing it with a guessed `Resource` scope can silently break create/update/delete operations. A dedicated apply-role, permissions boundary, and a tested IAM policy simulator/plan workflow are recommended before broad changes.

### EC2 and application

Both instances require IMDSv2 and use encrypted 8 GiB gp3 root disks. The app has no public IP. The AMI is selected as the most recent matching Amazon Linux 2023 image, which improves patch freshness but can cause replacement/update differences over time. No automatic patch management, vulnerability reporting, EDR, or host-level CloudWatch agent is configured. Nginx installs packages at boot; the private app currently installs none in user data.

### Encryption and secrets

EBS encryption is configured. HTTPS is used between client and Nginx, but trust is not established because the certificate is self-signed. App traffic from Nginx to Python is unencrypted HTTP within the VPC and controlled by security groups. No secret manager, KMS CMK, remote state, or application secret exists in declared configuration. Local state must be treated as sensitive even if current outputs are mainly identifiers and addresses.

### Monitoring and logging

Four CloudWatch alarms cover CPU and EC2 status checks for both instances. They have no actions/notification targets. No log group, agent, retention period, CloudTrail, GuardDuty, Config, WAF or flow log is declared. Detection of IAM activity and application-level failures is therefore incomplete.

## Connectivity alternatives for the private app

| Option | Benefits | Trade-offs |
|---|---|---|
| No outbound internet (current) | Smallest external attack surface, no recurring network service cost. | No OS repositories or SSM endpoint reachability; updates/log export require another mechanism. |
| NAT Gateway | Managed, resilient outbound internet for private subnets; simple route model. | Hourly plus data processing charges; broad outbound access unless egress is further controlled. |
| NAT instance | Lower idle cost for a very small lab, customizable filtering. | Must patch and operate it; single point of failure unless made redundant; forwarding/routing hardening required. |
| VPC interface/gateway endpoints | Private AWS-service access without general internet; can support SSM and CloudWatch Logs. | Per-endpoint/AZ charges for interface endpoints; only selected AWS services reachable, not general package sites. |
| Controlled management path | Keep app isolated and use baked AMIs, signed artifacts or a controlled proxy/deployment path. | More build/deployment work; may delay emergency package access. |

## Verification boundaries

Static review and offline scanners can validate source structure and common misconfiguration patterns. They cannot establish deployed state, actual effective IAM permissions, certificate trust, application runtime behavior, billing, SSM connectivity or CloudTrail delivery. Those require an explicitly authorized read-only account review and a controlled deployment/test plan.

## Offline validation results

Results are from the source on this branch. No AWS credentials were used, and no live AWS API call or deployment command was run.

| Check | Command | Result |
|---|---|---|
| Terraform formatting | `terraform fmt -check -recursive` | Passed after formatting. |
| Terraform validation | `terraform init -backend=false -input=false && terraform validate` | Passed with Terraform 1.17.2 and AWS provider 6.73.0. No backend or AWS account access was used. |
| TFLint | `tflint --recursive` (0.66.0) | Passed after adding explicit Terraform version and AWS provider constraints to root and module configurations. |
| Checkov | `checkov -d . --framework terraform --skip-path .terraform --soft-fail --hard-fail-on CKV_AWS_356` (3.4.11) | 84 passed, 8 failed. The command fails on `CKV_AWS_356` because the Terraform user policy still combines restrictable EC2 lifecycle actions with `Resource = "*"`. Other findings include expected public web IP, detailed monitoring/EBS optimization, IAM user attachment, and no VPC flow logs. The default security group finding is resolved. |
| Trivy IaC | `trivy config --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .terraform .` (0.76.2) | Fails on `AWS-0104` (CRITICAL): web egress TCP 443 is open to `0.0.0.0/0`. This is currently retained for package bootstrap and possible public SSM access; it is a real residual risk, not a false positive. Replace it with controlled egress before production. |
| Gitleaks | `gitleaks git --redact --no-banner .` (8.30.1) | Passed; 9 commits and about 38 KB scanned, no leaks reported. |
| Diff whitespace | `git diff --check` | Run before commit. |

The Checkov and Trivy gates are intentionally not green while the source has the above unresolved high/critical findings.
