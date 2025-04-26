variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "backend_alb_sg_id" {
  description = "ID of the backend ALB security group"
  type        = string
}

variable "ecs_tasks_sg_id" {
  description = "ID of the ECS tasks security group"
  type        = string
}

variable "api_image" {
  description = "Docker image for the API service"
  type        = string
  default     = "nginx:latest"  # Replace with your actual image
}

variable "api_port" {
  description = "Port that the API will listen on"
  type        = number
  default     = 8080
}

variable "api_cpu" {
  description = "CPU units for the API task (1 vCPU = 1024)"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory for the API task in MiB"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Desired number of API tasks"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "api_certificate_arn" {
  description = "ARN of the SSL certificate for the API ALB"
  type        = string
  default     = ""
}