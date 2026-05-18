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
  ami           = data.aws_ami.debian.id
  instance_type = "t3.medium"

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_ssh.id, aws_security_group.private_http.id]
  key_name                    = aws_key_pair.open_web_ui.key_name
  subnet_id                   = aws_subnet.private.id

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
}

# Random password generation for Open WebUI user
resource "random_password" "password" {
  length  = 16
  special = false
}

# Create a TerraCurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "open_web_ui" {
  name   = "open_web_ui"
  url    = "https://ollama.aws.saanvisood.dev"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10

  depends_on = [aws_route53_record.ollama, aws_acm_certificate_validation.ollama]
}

# SSH key
resource "aws_key_pair" "open_web_ui" {
  key_name   = "open_web_ui"
  public_key = file("${path.module}/my-terraform-key.pub")
}
