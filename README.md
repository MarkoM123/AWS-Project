# AWS Cloud Security Lab – Terraform

Infrastructure as Code (IaC) project for building and managing a secure AWS environment using Terraform.

The purpose of this project is to develop practical experience with AWS infrastructure, cloud networking, IAM, workload security, and security monitoring, following common cloud security principles.

## Project Objectives

The project aims to demonstrate:

- Infrastructure provisioning using Terraform.
- AWS VPC networking and subnet segmentation.
- Separation of public-facing and private workloads.
- IAM roles, policies, and least-privilege access.
- EC2 workload deployment and hardening.
- Secure communication using HTTPS.
- Network access control using Security Groups.
- Centralized logging and security monitoring.
- Modular and reusable Terraform configurations.
- Separation of development and production environments.

## Architecture Overview

The initial architecture consists of a public-facing WEB server and a private APP server deployed inside a dedicated VPC.

```text
                         INTERNET
                            |
                            |
                    Internet Gateway
                            |
                            |
                 +---------------------+
                 |      AWS VPC        |
                 |    10.50.0.0/16     |
                 |                     |
                 |  PUBLIC SUBNET      |
                 |  10.50.1.0/24       |
                 |                     |
                 |  +---------------+  |
                 |  |   WEB SERVER  |  |
                 |  |   Amazon EC2  |  |
                 |  |   Nginx HTTPS |  |
                 |  +-------+-------+  |
                 |          |          |
                 |          | TCP 8080 |
                 |          |          |
                 |  PRIVATE SUBNET     |
                 |  10.50.2.0/24       |
                 |                     |
                 |  +---------------+  |
                 |  |   APP SERVER  |  |
                 |  |   Amazon EC2  |  |
                 |  | Python Backend|  |
                 |  +---------------+  |
                 |                     |
                 +---------------------+
```

### AWS Environment

| Component | Configuration |
|---|---|
| Cloud Provider | Amazon Web Services |
| Region | eu-north-1 (Stockholm) |
| Infrastructure as Code | Terraform |
| Terraform AWS Provider | 6.x |
| Operating System | Amazon Linux 2023 |
| EC2 Instance Type | t3.micro |
| VPC CIDR | 10.50.0.0/16 |
| Public Subnet | 10.50.1.0/24 |
| Private Subnet | 10.50.2.0/24 |
| WEB Server | Nginx |
| APP Server | Python HTTP Server |
| WEB Protocol | HTTPS |
| Backend Protocol | HTTP, TCP 8080 |

## Network Architecture

### VPC

A dedicated VPC named `terraform-lab-vpc` is provisioned with CIDR range `10.50.0.0/16`.

VPC configuration:
- DNS resolution enabled.
- DNS hostnames enabled.
- Internet Gateway attached.

### Public Subnet

CIDR: `10.50.1.0/24`

The public subnet hosts the WEB EC2 instance.

Its route table contains:
- Local VPC route.
- Default route `0.0.0.0/0` through the Internet Gateway.

### Private Subnet

CIDR: `10.50.2.0/24`

The private subnet hosts the APP EC2 instance.

Its route table contains:
- Local VPC route.
- No default route to the internet.
- No NAT Gateway.

The absence of a NAT Gateway prevents direct outbound internet access from the private subnet. Communication between public and private subnets is supported through the VPC local route.

### Security Groups

Two Security Groups implement workload-level network segmentation.

**WEB Security Group**

Inbound:
- TCP 443 from `0.0.0.0/0`.

Outbound:
- TCP 8080 to the APP Security Group.
- TCP 443 to `0.0.0.0/0`.

**APP Security Group**

Inbound:
- TCP 8080 exclusively from the WEB Security Group.

Security Groups are stateful, allowing return traffic for permitted connections.

## Compute Layer

### WEB Server

The WEB server is deployed in the public subnet.

Components:
- Amazon Linux 2023.
- Nginx.
- OpenSSL.
- HTTPS listener on TCP 443.
- Self-signed TLS certificate.
- Nginx reverse proxy configuration.

The WEB server forwards incoming HTTPS requests to the private APP server over TCP 8080.

### APP Server

The APP server is deployed in the private subnet.

Components:
- Amazon Linux 2023.
- Python 3.
- Python HTTP Server.
- Systemd service for application management.

The backend application returns JSON responses containing server information, request path, and timestamp.

The APP server does not have a public IP address and is not intended to be accessed directly from the internet.

## IAM and Access Management

The project uses separate AWS CLI profiles for infrastructure administration and lab operations.

| Profile | Purpose |
|---|---|
| terraform-admin | IAM administration |
| terraform-lab | Infrastructure provisioning |

IAM resources include:

- `Terraform_policy` – customer-managed policy for Terraform operations.
- `terraform-lab-ec2-ssm-role` – IAM role assumed by EC2.
- `terraform-lab-ec2-instance-profile` – instance profile attached to EC2.
- `AmazonSSMManagedInstanceCore` – AWS managed policy for Systems Manager access.

The IAM module is configured to use the aliased administrative AWS provider.

## Terraform Project Structure

```text
aws-lab/
│
├── versions.tf
├── providers.tf
├── main.tf
├── variables.tf
├── terraform.tfvars.example
├── outputs.tf
├── locals.tf
├── data.tf
│
├── networking.tf
├── security-groups.tf
├── iam.tf
├── ec2.tf
├── logging.tf
├── security-services.tf
│
├── modules/
│   ├── networking/
│   ├── security-groups/
│   ├── iam/
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── templates/
│   │       ├── app-user-data.sh.tftpl
│   │       └── web-user-data.sh.tftpl
│   ├── logging/
│   └── security-services/
│
├── environments/
│   ├── dev/
│   └── prod/
│
├── policies/
│   ├── iam/
│   └── security/
│
├── README.md
└── .gitignore
```

The project uses a root Terraform module and separate child modules. The modularization process is ongoing.

## Prerequisites

Required tools:

- AWS CLI v2.
- Terraform CLI.
- Git.
- An AWS account with the required permissions.
- Windows PowerShell or another supported terminal.

AWS CLI profiles must be configured before running Terraform.

Example profile verification:

```powershell
aws sts get-caller-identity --profile terraform-lab
aws sts get-caller-identity --profile terraform-admin
```

## Terraform Deployment

Run commands from the project root directory.

### 1. Initialize Terraform

```powershell
terraform init
```

### 2. Validate configuration

```powershell
terraform validate
```

### 3. Format Terraform files

```powershell
terraform fmt -recursive
```

### 4. Review execution plan

```powershell
terraform plan
```

### 5. Apply infrastructure

```powershell
terraform apply
```

Review the proposed changes before approving the deployment.

### 6. Inspect Terraform state

```powershell
terraform state list
```

Inspect a specific resource:

```powershell
terraform state show module.compute.aws_instance.web
```

### 7. Destroy infrastructure

```powershell
terraform destroy
```

**Warning:** This command destroys managed infrastructure. Always review the execution plan and understand the consequences before confirming.

## Remote Management

AWS Systems Manager Session Manager is used to access supported EC2 instances without requiring inbound SSH access.

Example:

```powershell
aws ssm start-session `
  --target INSTANCE_ID `
  --profile terraform-admin `
  --region eu-north-1
```

The private APP instance currently has no direct connectivity to Systems Manager because the private subnet has no NAT Gateway or SSM VPC endpoints. No additional paid connectivity resources are included in the current design.

## Security Considerations

The project incorporates the following security principles:

- Network segmentation between public and private workloads.
- Restricted inbound access to the APP server.
- IAM role-based access for EC2.
- Separation of administrative and infrastructure provisioning identities.
- HTTPS for external WEB communication.
- Encrypted EBS volumes.
- IMDSv2 requirement for EC2 instances.
- No hardcoded AWS access keys in Terraform configuration.
- Sensitive Terraform files excluded from Git.

The current IAM policy is designed for the lab environment and should be further restricted before production use.

The WEB TLS certificate is self-signed and is intended for testing, not production deployment.

## Current Implementation Status

| Component | Status |
|---|---|
| VPC | Implemented |
| Public and private subnets | Implemented |
| Internet Gateway | Implemented |
| Route tables | Implemented |
| Network ACL | Implemented |
| Security Groups | Implemented |
| IAM role and policy | Implemented |
| EC2 WEB instance | Running |
| Nginx HTTPS | Configured and running |
| EC2 APP instance | Running |
| Python backend | Deployment troubleshooting |
| WEB-to-APP connectivity | Pending validation |
| CloudWatch logging | Planned |
| GuardDuty | Planned |
| Security Hub | Planned |
| Further Terraform modularization | In progress |
| Dev/Prod environment separation | Planned |

**Known issue:** The APP instance's cloud-init `scripts-user` module fails during User Data execution. The backend service has therefore not yet been verified as operational. A diagnostic User Data update is being prepared to capture the exact failure during the next APP instance deployment.

## Planned Improvements

Future development includes:

1. Complete the WEB-to-APP communication.
2. Improve Terraform module organization.
3. Implement centralized CloudWatch logging.
4. Integrate Amazon GuardDuty.
5. Integrate AWS Security Hub.
6. Implement AWS CloudTrail monitoring.
7. Improve IAM least-privilege permissions.
8. Introduce separate Dev and Prod configurations.
9. Add automated Terraform security checks.
10. Implement infrastructure validation and deployment automation through GitHub Actions.

## Cost Management

This project is designed as a cost-conscious AWS lab.

The current architecture avoids:
- NAT Gateway.
- Paid VPC interface endpoints.
- Unnecessary always-on infrastructure.

EC2 instances, EBS volumes, public IPv4 addresses, logging, and security services may still incur charges. Review AWS pricing and billing before enabling additional services.

Terminate or destroy resources when they are no longer required.

## Repository

GitHub: https://github.com/MarkoM123/AWS-Project

---

**Project:** AWS Cloud Security Lab  
**Infrastructure as Code:** Terraform  
**Cloud Provider:** Amazon Web Services  
**Primary Focus:** Cloud Infrastructure, Networking, IAM and Security Engineering
