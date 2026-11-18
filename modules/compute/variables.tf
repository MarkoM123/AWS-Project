
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_subnet_id" {
  description = "Public subnet ID for WEB instance"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for APP instance"
  type        = string
}

variable "web_security_group_id" {
  description = "WEB Security Group ID"
  type        = string
}

variable "app_security_group_id" {
  description = "APP Security Group ID"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM Instance Profile name for EC2 instances"
  type        = string
}
