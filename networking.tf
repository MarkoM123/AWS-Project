resource "aws_vpc" "lab" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "terraform-lab-vpc"
    Environment = "Lab"
  }
}

# The default security group is not attached to either workload. Remove its
# AWS-created self-ingress and allow-all egress rules to prevent future use.
resource "aws_default_security_group" "lab" {
  vpc_id  = aws_vpc.lab.id
  ingress = []
  egress  = []

  tags = {
    Name        = "terraform-lab-default-sg"
    Environment = "Lab"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.50.1.0/24"
  availability_zone = "eu-north-1b"
  # Only the web instance requests a public IP explicitly; do not assign one
  # automatically to future workloads placed in this subnet.
  map_public_ip_on_launch = false

  tags = {
    Name = "terraform-lab-public"
    Type = "Public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.50.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "terraform-lab-private"
    Type = "Private"
  }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "terraform-lab-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "terraform-lab-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "terraform-lab-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
