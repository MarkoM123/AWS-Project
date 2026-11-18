
output "terraform_policy_arn" {
  description = "ARN of the Terraform lab IAM policy"
  value       = aws_iam_policy.terraform_lab.arn
}
