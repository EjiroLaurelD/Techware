/*
  DNS Module: Creates Route53 records for frontend and backend
*/

# Route53 hosted zone
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# Certificate for frontend domain
resource "aws_acm_certificate" "frontend" {
  domain_name       = "app.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name        = "${var.project_name}-frontend-cert"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS record for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "frontend" {
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Certificate for backend domain (internal)
resource "aws_acm_certificate" "backend" {
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name        = "${var.project_name}-backend-cert"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS record for backend certificate validation
resource "aws_route53_record" "backend_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.backend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

# Backend certificate validation
resource "aws_acm_certificate_validation" "backend" {
  certificate_arn         = aws_acm_certificate.backend.arn
  validation_record_fqdns = [for record in aws_route53_record.backend_cert_validation : record.fqdn]
}

# DNS record for frontend
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.frontend_lb_dns_name
    zone_id                = var.frontend_lb_zone_id
    evaluate_target_health = true
  }
}

# DNS record for backend (internal)
resource "aws_route53_record" "backend" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.backend_lb_dns_name
    zone_id                = var.backend_lb_zone_id
    evaluate_target_health = true
  }
}