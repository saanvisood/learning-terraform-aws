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

# AWS will create VPC first, then attempt to create the subnet and IGW in
# parallel because they are both dependent on the VPC

# Subnet
resource "aws_subnet" "subnet" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui.cidr_block, 3, 1)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "ca-central-1a"
}

# IGW
resource "aws_internet_gateway" "open_web_ui" {
  vpc_id = aws_vpc.open_web_ui.id
}

# Route table
resource "aws_route_table" "open_web_ui" {
  vpc_id = aws_vpc.open_web_ui.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.open_web_ui.id
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "open_web_ui" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.open_web_ui.id
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

# SSH key
resource "aws_key_pair" "open_web_ui" {
  key_name   = "open_web_ui"
  public_key = file("${path.module}/my-terraform-key.pub")
}

# Spot instance
resource "aws_spot_instance_request" "open_web_ui" {
  ami           = data.aws_ami.debian.id
  instance_type = "t3.medium"

  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ssh.id,
  aws_security_group.http.id]
  key_name             = aws_key_pair.open_web_ui.key_name
  subnet_id            = aws_subnet.subnet.id
  wait_for_fulfillment = true

  user_data_base64 = base64encode(
    templatefile("${path.module}/scripts/provision_vars.sh",
      {
        open_webui_user    = var.open_webui_user,
        open_webui_passwrd = random_password.password.result,
        openai_base        = var.openai_base,
        openai_key         = var.openai_key
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
  url    = "http://${aws_spot_instance_request.open_web_ui.public_ip}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}
