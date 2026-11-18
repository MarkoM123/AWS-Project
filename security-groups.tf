
# WEB Security Group
resource "aws_security_group" "web" {
  name        = "terraform-lab-web-sg"
  description = "Security Group for public web server"
  vpc_id      = aws_vpc.lab.id

  egress = []

  tags = {
    Name        = "terraform-lab-web-sg"
    Environment = "Lab"
    Tier        = "Web"
  }
}

# APP Security Group
resource "aws_security_group" "app" {
  name        = "terraform-lab-app-sg"
  description = "Security Group for private application server"
  vpc_id      = aws_vpc.lab.id

  egress = []

  tags = {
    Name        = "terraform-lab-app-sg"
    Environment = "Lab"
    Tier        = "Application"
  }
}

# WEB: Allow HTTPS from Internet
resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTPS from Internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# WEB: Allow traffic to APP on TCP 8080
resource "aws_vpc_security_group_egress_rule" "web_to_app" {
  security_group_id            = aws_security_group.web.id
  description                  = "Allow traffic to APP"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.app.id
}

# APP: Allow traffic only from WEB Security Group
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application traffic only from WEB"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.web.id
}

# Outputs
output "web_security_group_id" {
  description = "WEB Security Group ID"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "APP Security Group ID"
  value       = aws_security_group.app.id
}
