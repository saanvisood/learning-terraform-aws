# R53 A type record and alias
resource "aws_route53_record" "ollama" {
  zone_id = data.aws_route53_zone.aws_subdomain.zone_id
  name    = "ollama.aws.saanvisood.dev"
  type    = "A"

  alias {
    name                   = aws_lb.ollama.dns_name
    zone_id                = aws_lb.ollama.zone_id
    evaluate_target_health = true
  }
}

# ACM
resource "aws_acm_certificate" "ollama" {
  domain_name       = "ollama.aws.saanvisood.dev"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "ollama" {
  certificate_arn         = aws_acm_certificate.ollama.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ACM DNS Validation through Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ollama.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.aws_subdomain.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Subdomain name as data
data "aws_route53_zone" "aws_subdomain" {
  name = "aws.saanvisood.dev"
}
