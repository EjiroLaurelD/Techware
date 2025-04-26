output "frontend_alb_sg_id" {
  description = "ID of the frontend ALB security group"
  value       = aws_security_group.frontend_alb.id
}

output "frontend_instance_sg_id" {
  description = "ID of the frontend instance security group"
  value       = aws_security_group.frontend_instance.id
}

output "backend_alb_sg_id" {
  description = "ID of the backend ALB security group"
  value       = aws_security_group.backend_alb.id
}

output "ecs_tasks_sg_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "frontend_instance_profile_name" {
  description = "Name of the frontend instance profile"
  value       = aws_iam_instance_profile.frontend_profile.name
}

output "frontend_role_arn" {
  description = "ARN of the frontend role"
  value       = aws_iam_role.frontend_role.arn
}