
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Private APP EC2 instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.app_security_group_id]

  associate_public_ip_address = false
  iam_instance_profile        = var.instance_profile_name

  user_data = templatefile(
    "${path.module}/templates/app-user-data.sh.tftpl",
    {}
  )

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "terraform-lab-app"
    Environment = "Lab"
    Tier        = "Application"
  }
}

# Public WEB EC2 instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_security_group_id]

  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile_name

  user_data = templatefile(
    "${path.module}/templates/web-user-data.sh.tftpl",
    {
      app_private_ip = aws_instance.app.private_ip
    }
  )

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "terraform-lab-web"
    Environment = "Lab"
    Tier        = "Web"
  }
}
