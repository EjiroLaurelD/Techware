output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

# output "frontend_url" {
#   description = "URL of the frontend application"
#   value       = "https://${module.dns.frontend_domain}"
# }

# output "backend_url" {
#   description = "URL of the backend API"
#   value       = "https://${module.dns.backend_domain}"
# }

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.ecs_cluster_name
}

output "frontend_asg_name" {
  description = "Name of the frontend Auto Scaling Group"
  value       = module.frontend.frontend_asg_name
}

output "frontend_url" {
  description = "URL of the frontend application load balancer"
  value       = module.frontend.frontend_lb_dns_name
}

output "backend_url" {
  description = "URL of the backend application load balancer"
  value       = module.ecs.api_lb_dns_name
}