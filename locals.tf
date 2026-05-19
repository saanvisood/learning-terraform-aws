locals {
  all_traffic_cidr    = "0.0.0.0/0"
  vpc_cidr            = "10.0.0.0/16"
  port_0              = 0
  all_protocols       = "-1"
  ssh_port            = "22"
  http_port           = "80"
  https_port          = "443"
  tcp                 = "tcp"
  http                = "http"
  https               = "https"
  ssh                 = "ssh"
  latest_aws_provider = "~> 6.44.0"
  latest_terracurl_v  = "2.2.0"
  latest_random_v     = "3.6.2"
  alb_url             = "https://ollama.aws.saanvisood.dev"
  ssl_policy          = "ELBSecurityPolicy-2016-08"
}
