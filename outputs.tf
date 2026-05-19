output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "alb_url" {
  value = local.alb_url
}

output "password" {
  sensitive = true
  value     = random_password.password.result
}
