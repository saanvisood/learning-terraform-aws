data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_password" "password" {
  length  = 16
  special = false
}


# VPC
resource "aws_vpc" "open_web_ui" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}


# Public subnets (for ALB and bastion)
resource "aws_subnet" "public_a" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui, cidr_block, 3, 0)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1a"
}

resource "aws_subnet" "public_b" {
  cidr_block        = cidrsubnet(aws_instance.open_web_ui, cidr_block, 3, 1)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1a"
}


# Private subnet (Open WebUI instance)
resource "aws_subnet" "private" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui.cidr_block, 3, 2)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1b"
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


# ACM
resource "aws_acm_certificate" "ollama" {
  domain_name       = "ollama.aws.saanvisood.dev"
  validation_method = "DNS"
}


# ALB
resource "aws_lb" "ollama" {
  name               = "ollama-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}


# Target group
resource "aws_lb_target_group" "ollama" {
  name     = "ollama-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.open_web_ui.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "ollama" {
  target_group_arn = aws_lb_target_group.ollama.arn
  target_id        = aws_instance.open_web_ui.id
  port             = 80
}


# Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ollama.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ollama.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ollama.arn
  }
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


# Security group - HTTPS
resource "aws_security_group" "https" {
  name = "allow-all-https"

  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group - HTTP
resource "aws_security_group" "http" {
  name = "allow-all-http"

  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group - SSH
resource "aws_security_group" "ssh" {
  name = "allow-all-ssh"

  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# SSH key
resource "aws_key_pair" "open_web_ui" {
  key_name   = "open_web_ui"
  public_key = file("${path.module}/my-terraform-key.pub")
}


# On-demand instance
resource "aws_instance" "open_web_ui" {
  ami           = data.aws_ami.debian.id
  instance_type = "t3.medium"

  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ssh.id,
  aws_security_group.http.id]
  key_name  = aws_key_pair.open_web_ui.key_name
  subnet_id = aws_subnet.private.id

  user_data_base64 = base64encode(
    templatefile("${path.module}/scripts/provision_vars.sh",
      {
        open_webui_user   = var.open_webui_user,
        open_webui_passwd = random_password.password.result,
        openai_base       = var.openai_base,
        openai_key        = var.openai_key
  }))

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "CheapWorker"
  }
}


# Create a TerraCurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "open_web_ui" {
  name   = "open_web_ui"
  url    = "http://${aws_instance.open_web_ui.public_ip}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}
