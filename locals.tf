locals {
  all_traffic_cidr = "0.0.0.0/0"
  vpc_cidr         = "10.0.0.0/16"
  port_0           = 0
  ssh_port         = 22
  http_port        = 80
  https_port       = 443
  all_protocols    = "-1"
  tcp              = "TCP"
  ssh              = "SSH"
  http             = "HTTP"
  https            = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-2016-08"
  alb_url          = "https://ollama.aws.saanvisood.dev"
}
