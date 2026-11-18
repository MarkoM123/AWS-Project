
output "web_instance_id" {
  description = "WEB EC2 instance ID"
  value       = aws_instance.web.id
}

output "web_public_ip" {
  description = "WEB EC2 public IP"
  value       = aws_instance.web.public_ip
}

output "web_public_dns" {
  description = "WEB EC2 public DNS"
  value       = aws_instance.web.public_dns
}

output "app_instance_id" {
  description = "APP EC2 instance ID"
  value       = aws_instance.app.id
}

output "app_private_ip" {
  description = "APP EC2 private IP"
  value       = aws_instance.app.private_ip
}
