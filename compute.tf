# Bastion host
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.debian.id
  instance_type = "t3.micro"

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  key_name                    = aws_key_pair.open_web_ui.key_name
  subnet_id                   = aws_subnet.public_a.id

  tags = {
    Name = "bastion"
  }
}

# On-demand instance (where ollama will run)
resource "aws_instance" "open_web_ui" {
  ami           = data.aws_ami.deep_learning_gpu.id
  instance_type = "g4dn.2xlarge"

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_ssh.id, aws_security_group.private_http.id]
  key_name                    = aws_key_pair.open_web_ui.key_name
  subnet_id                   = aws_subnet.private.id

  depends_on = [aws_nat_gateway.main]

  # user_data_base64 = base64encode(
  #   templatefile("${path.module}/scripts/provision_vars.sh",
  #     {
  #       open_webui_user   = var.open_webui_user,
  #       open_webui_passwd = random_password.password.result,
  #       openai_base       = var.openai_base,
  #       openai_key        = var.openai_key
  # }))

  root_block_device {
    volume_size = 150
    volume_type = "gp3"
  }
}

# Dynamically fetch the latest Ubuntu 22.04 Deep Learning GPU AMI
data "aws_ami" "deep_learning_gpu" {
  most_recent = true
  owners      = ["amazon"] # Official AWS image provider account

  filter {
    name   = "name"
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

