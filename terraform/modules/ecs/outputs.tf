output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "api_task_definition_arn" {
  description = "ARN of the API task definition"
  value       = aws_ecs_task_definition.api.arn
}

output "api_service_name" {
  description = "Name of the API ECS service"
  value       = aws_ecs_service.api.name
}

output "api_lb_dns_name" {
  description = "DNS name of the API load balancer"
  value       = aws_lb.api.dns_name
}

output "api_lb_arn" {
  description = "ARN of the API load balancer"
  value       = aws_lb.api.arn
}

output "api_lb_zone_id" {
  description = "Zone ID of the API load balancer"
  value       = aws_lb.api.zone_id
}