
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ============================================================
# TERRAFORM EXECUTION POLICY
# ============================================================

data "aws_iam_policy_document" "terraform_lab" {

  # VPC, Networking, Security Groups and EC2 permissions
  statement {
    sid    = "TerraformInfrastructurePermissions"
    effect = "Allow"

    actions = [
      # VPC
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",

      # Subnets
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",

      # Internet Gateway
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",

      # Route Tables
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",

      # Security Groups
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",

      # EC2 Instances
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:ModifyInstanceAttribute",

      # EBS Volumes
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",

      # Network Interfaces
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",

      # Instance Profile association
      "ec2:AssociateIamInstanceProfile",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:ReplaceIamInstanceProfileAssociation",

      # Tags and Describe
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:Describe*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["eu-north-1"]
    }
  }

  # Allow passing only the dedicated EC2 IAM Role
  statement {
    sid    = "AllowPassEC2SSMRole"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::457136874735:role/terraform-lab-ec2-ssm-role"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

# ============================================================
# EXISTING TERRAFORM IAM POLICY
# ============================================================

resource "aws_iam_policy" "terraform_lab" {
  name   = "Terraform_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.terraform_lab.json
}

# Attach policy to existing Terraform IAM user
resource "aws_iam_user_policy_attachment" "terraform_lab" {
  user       = "terraform-lab"
  policy_arn = aws_iam_policy.terraform_lab.arn
}

# ============================================================
# EC2 IAM ROLE
# ============================================================

# Trust policy - allow EC2 service to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name               = "terraform-lab-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "terraform-lab-ec2-ssm-role"
    Environment = "Lab"
  }
}

# AWS managed policy for Systems Manager
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "terraform-lab-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = {
    Name        = "terraform-lab-ec2-instance-profile"
    Environment = "Lab"
  }
}
