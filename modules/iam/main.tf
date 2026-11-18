terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
# Existing Terraform IAM policy document
data "aws_iam_policy_document" "terraform_lab" {
  statement {
    sid    = "TerraformVPCLabPermissions"
    effect = "Allow"

    actions = [
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:Describe*",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["eu-north-1"]
    }
  }
}

# Existing customer-managed IAM policy
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
