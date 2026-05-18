output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "alb_url" {
  value = "https://ollama.aws.saanvisood.dev"
}

output "password" {
  sensitive = true
  value     = random_password.password.result
}
