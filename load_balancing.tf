# ALB
resource "aws_lb" "ollama" {
  name               = "ollama-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# Target group
resource "aws_lb_target_group" "ollama" {
  name     = "ollama-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.open_web_ui.id

  health_check {
    path = "/"
  }
}

# Target group attachment
resource "aws_lb_target_group_attachment" "ollama" {
  target_group_arn = aws_lb_target_group.ollama.arn
  target_id        = aws_instance.open_web_ui.id
  port             = 80
}

# Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ollama.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ollama.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ollama.arn
  }
}
