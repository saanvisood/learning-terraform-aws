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

# Create a TerraCurl request to check if the web server is up and running
# Wait a max of 20 min, retry every 10 sec
data "terracurl_request" "open_web_ui" {
  name   = "open_web_ui"
  url    = local.alb_url
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10

  depends_on = [aws_route53_record.ollama, aws_acm_certificate_validation.ollama]
}

# Random password generation for Open WebUI user
resource "random_password" "password" {
  length  = 16
  special = true
}

# Creating AWS Secrets Manager container
resource "aws_secretsmanager_secret" "open_webui_secret" {
  name                    = "open-webui-admin-credentials"
  description             = "Open WebUI admin credentials"
  recovery_window_in_days = 7
}

# Storing credentials inside secret container
resource "aws_secretsmanager_secret_version" "open_webui_secret" {
  secret_id = aws_secretsmanager_secret.open_webui_secret.id
  secret_string = jsonencode({
    username = "admin@demo.gs"
    password = random_password.password.result
  })
}

# SSH key
resource "aws_key_pair" "open_web_ui" {
  key_name   = "open_web_ui"
  public_key = file("${path.module}/my-terraform-key.pub")
}
