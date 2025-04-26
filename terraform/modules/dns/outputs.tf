output "frontend_domain" {
  description = "Frontend domain name"
  value       = aws_route53_record.frontend.name
}

output "backend_domain" {
  description = "Backend domain name"
  value       = aws_route53_record.backend.name
}

output "frontend_certificate_arn" {
  description = "ARN of the frontend certificate"
  value       = aws_acm_certificate.frontend.arn
}

output "backend_certificate_arn" {
  description = "ARN of the backend certificate"
  value       = aws_acm_certificate.backend.arn
}