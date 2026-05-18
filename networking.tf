# VPC
resource "aws_vpc" "open_web_ui" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Public subnet (ALB)
resource "aws_subnet" "public_a" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui.cidr_block, 3, 0)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1a"
}

# Public subnet (Bastion host)
resource "aws_subnet" "public_b" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui.cidr_block, 3, 1)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1b"
}

# Private subnet (Open WebUI instance)
resource "aws_subnet" "private" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui.cidr_block, 3, 2)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1a"
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
}

# IGW
resource "aws_internet_gateway" "open_web_ui" {
  vpc_id = aws_vpc.open_web_ui.id
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.open_web_ui.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.open_web_ui.id
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private route table (outbound through NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.open_web_ui.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

# Associate private route table with private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
