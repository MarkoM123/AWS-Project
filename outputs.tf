output "vpc_id" {
  description = "ID of the lab VPC"
  value       = aws_vpc.lab.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "web_instance_id" {
  description = "WEB EC2 instance ID"
  value       = module.compute.web_instance_id
}

output "web_public_ip" {
  description = "WEB EC2 public IP"
  value       = module.compute.web_public_ip
}

output "web_public_dns" {
  description = "WEB EC2 public DNS"
  value       = module.compute.web_public_dns
}

output "app_instance_id" {
  description = "APP EC2 instance ID"
  value       = module.compute.app_instance_id
}

output "app_private_ip" {
  description = "APP EC2 private IP"
  value       = module.compute.app_private_ip
}
