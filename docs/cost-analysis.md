# Cost analysis

## Current declared stack

The repository defines resources that can incur recurring or usage-based charges when deployed. This is a qualitative inventory, not an invoice estimate: actual cost depends on uptime, exact pricing date, region, data volume and account-level free-tier/discount eligibility.

| Resource or behavior | Cost driver | Cost control |
|---|---|---|
| Two `t3.micro` EC2 instances | Instance-hours and possible CPU credit behavior | Stop or destroy the lab when idle; validate current regional instance pricing before deployment. |
| Two 8 GiB gp3 EBS root volumes | Provisioned storage while volumes exist | Keep volumes small; `delete_on_termination = true` helps avoid orphaned root disks. |
| Web public IPv4 address | Public IPv4 hourly pricing while allocated/in use | Remove the public endpoint when the lab is idle; public IPv4 may be charged even when attached. |
| CloudWatch metric alarms | Alarm count and any custom metric ingestion | Four alarms are configured; they use EC2 metrics. No logs or custom metrics are configured. |
| Internet data transfer | Traffic to/from the internet | Keep responses small; web 443 egress supports bootstrap and outbound HTTPS. |
| Terraform state | No AWS charge while local | Local state avoids backend cost but shifts confidentiality, backup and locking duties to the operator. |

The app subnet has no NAT Gateway or interface endpoints. This avoids recurring networking charges but leaves the app without SSM or general outbound connectivity. Do not estimate actual project spend from this source alone; use the AWS Pricing Calculator for `eu-north-1` and check Cost Explorer after an authorized deployment.

## Changes in this branch

No new AWS resources are introduced. IAM policy changes, app systemd hardening, Nginx changes, documentation and GitHub Actions scanners do not create AWS charges by themselves. The workflow consumes GitHub-hosted runner minutes and downloads scanner tools; it has no AWS credentials and does not run a plan or deployment.

## Optional follow-up services

| Option | Security/operations purpose | Cost and complexity | Recommendation for this lab |
|---|---|---|---|
| CloudTrail management-event trail to S3 | Durable account API audit history and investigation evidence; multi-region collection and log file validation improve coverage/integrity. | S3 storage, requests, data transfer and possible CloudTrail charges for additional copies/events; bucket policy, retention and lifecycle need review. First management-event copy pricing depends on account/trail context. | Strong production recommendation, but add only after reviewing retention, bucket ownership and exact pricing. No data events by default. |
| CloudWatch Logs + Agent | Central Nginx, app and system logs with retention and query support. | Ingestion and storage charges. The private app also needs a path to Logs, through endpoints or a controlled egress route. | Useful next step after choosing retention and private connectivity. |
| SSM interface endpoints | Private app management without SSH or general internet routing. | Interface endpoint hourly and data processing charges per AZ/service; likely several endpoints for full SSM messaging. | Compare to a controlled management/build path; do not add automatically to a one-AZ low-cost lab. |
| NAT Gateway | General outbound connectivity for private instances. | Hourly and per-GB processing charges; often the largest fixed network cost in a small lab. | Avoid unless general private egress is a firm requirement. |
| NAT instance | Lower-cost general egress for a tiny lab. | EC2 cost plus operator effort, patching and availability risk. | Only if the owner accepts managing the network appliance. |
| GuardDuty | Managed threat detection from AWS telemetry such as CloudTrail, VPC/DNS and runtime signals depending on feature plan. | Usage-based and feature-specific charges. | Optional; enable after reviewing current price model and intended coverage. |
| AWS Config | Resource configuration history and compliance evaluation. | Configuration item recording and rule evaluation charges. | Valuable for longer-lived accounts; can be costly/noisy for a small short-lived lab. |
| AWS WAF | Layer 7 request filtering and managed rule groups in front of a supported ingress. | Web ACL, rule and request charges; typically pairs with ALB/CloudFront, changing current topology. | Consider only when the endpoint and threat model justify the architecture/cost. |
| ALB + ACM | Stable ingress, health checks and trusted public TLS certificate lifecycle. | Load balancer hours, capacity units and data processing; DNS may add cost. ACM public certificates generally avoid certificate charges for supported integrations, but verify current terms. | Production direction for availability and trusted TLS; it is a material architecture change. |
| S3 remote Terraform state | Central state access, versioning, encryption and state locking with supported Terraform backend behavior. | S3 storage/requests; optional KMS key charges. | Recommended for shared/prod work, but migrate only with a backup and explicit state migration plan. |

## Cost-saving practices

- Use `terraform plan` and review resource additions, replacements, public IPs and storage before any authorized apply.
- Stop or destroy lab resources when idle; confirm whether stop preserves billable EBS/public IPv4 resources.
- Avoid NAT Gateway and always-on optional security services unless the learning objective or threat model needs them.
- Set CloudWatch log retention if log groups are added. Keep CloudTrail management events by default and scope data events only where justified.
- Set AWS Budgets or billing alerts outside this Terraform stack if the account owner authorizes them.
- Re-check the AWS Pricing Calculator and regional prices before deployment; this document intentionally avoids stale dollar figures.
