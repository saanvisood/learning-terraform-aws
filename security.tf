# HTTPS
resource "aws_security_group" "https" {
  name   = "allow-all-https"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = local.https
    to_port     = local.https
    protocol    = local.tcp
    cidr_blocks = [local.all_traffic_cidr]
  }

  egress {
    from_port   = local.port_0
    to_port     = local.port_0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private HTTP from ALB
resource "aws_security_group" "private_http" {
  name   = "allow-http-from-alb"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.https.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH
resource "aws_security_group" "ssh" {
  name   = "allow-all-ssh"
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

# Private SSH from bastion
resource "aws_security_group" "private_ssh" {
  name   = "allow-ssh-from-bastion"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
