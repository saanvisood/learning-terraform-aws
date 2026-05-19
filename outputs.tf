output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "alb_url" {
  value = local.alb_url
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}
