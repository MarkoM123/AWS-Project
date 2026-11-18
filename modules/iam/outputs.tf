
output "terraform_policy_arn" {
  description = "ARN of the Terraform lab IAM policy"
  value       = aws_iam_policy.terraform_lab.arn
}

output "ec2_instance_profile_name" {
  description = "Instance Profile used by EC2 instances"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_iam_role_arn" {
  description = "IAM Role ARN assigned to EC2 instances"
  value       = aws_iam_role.ec2_ssm.arn
}
