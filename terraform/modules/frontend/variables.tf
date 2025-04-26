variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "frontend_alb_sg_id" {
  description = "ID of the frontend ALB security group"
  type        = string
}

variable "frontend_instance_sg_id" {
  description = "ID of the frontend instance security group"
  type        = string
}

variable "frontend_instance_profile_name" {
  description = "Name of the frontend instance profile"
  type        = string
}

variable "api_endpoint" {
  description = "Endpoint URL for the backend API"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for the ALB"
  type        = string
}