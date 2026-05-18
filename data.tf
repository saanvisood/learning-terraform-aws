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
  url    = "https://ollama.aws.saanvisood.dev"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10

  depends_on = [aws_route53_record.ollama, aws_acm_certificate_validation.ollama]
}

# Random password generation for Open WebUI user
resource "random_password" "password" {
  length  = 16
  special = false
}

# SSH key
resource "aws_key_pair" "open_web_ui" {
  key_name   = "open_web_ui"
  public_key = file("${path.module}/my-terraform-key.pub")
}
