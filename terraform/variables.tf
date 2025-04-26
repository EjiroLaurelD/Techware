variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "TechWare"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "admin_cidrs" {
  description = "List of CIDR blocks that can access the instances via SSH"
  type        = list(string)
  default     = ["123.4.5.6/32"] # Should be restricted based on allowed ips in production!
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "ejiro.live" 
}

variable "backend_port" {
  description = "Port that the backend API will listen on"
  type        = number
  default     = 8080
}

variable "api_image" {
  description = "Docker image for the API service"
  type        = string
  default     = "techware:1" # Replace with your actual image
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

variable "instance_type" {
  description = "EC2 instance type for frontend"
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