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
    protocol    = local.all_protocols
    cidr_blocks = [local.all_traffic_cidr]
  }
}

# Private HTTP from ALB
resource "aws_security_group" "private_http" {
  name   = "allow-http-from-alb"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port       = local.http
    to_port         = local.http
    protocol        = local.tcp
    security_groups = [aws_security_group.https.id]
  }

  egress {
    from_port   = local.port_0
    to_port     = local.port_0
    protocol    = local.all_protocols
    cidr_blocks = [local.all_traffic_cidr]
  }
}

# SSH
resource "aws_security_group" "ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = local.ssh
    to_port     = local.ssh
    protocol    = local.tcp
    cidr_blocks = [local.all_traffic_cidr]
  }

  egress {
    from_port   = local.port_0
    to_port     = loca.port_0
    protocol    = local.all_protocols
    cidr_blocks = [local.all_traffic_cidr]
  }
}

# Private SSH from bastion
resource "aws_security_group" "private_ssh" {
  name   = "allow-ssh-from-bastion"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port       = local.ssh
    to_port         = local.ssh
    protocol        = local.tcp
    security_groups = [aws_security_group.ssh.id]
  }

  egress {
    from_port   = local.port_0
    to_port     = local.port_0
    protocol    = local.all_protocols
    cidr_blocks = [local.all_traffic_cidr]
  }
}
