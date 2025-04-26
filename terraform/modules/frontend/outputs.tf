output "frontend_asg_name" {
  description = "Name of the frontend Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.name
}

output "frontend_launch_template_id" {
  description = "ID of the frontend Launch Template"
  value       = aws_launch_template.frontend.id
}

output "frontend_lb_dns_name" {
  description = "DNS name of the frontend load balancer"
  value       = aws_lb.frontend.dns_name
}

output "frontend_lb_arn" {
  description = "ARN of the frontend load balancer"
  value       = aws_lb.frontend.arn
}

output "frontend_lb_zone_id" {
  description = "Zone ID of the frontend load balancer"
  value       = aws_lb.frontend.zone_id
}