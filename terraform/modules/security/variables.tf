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

variable "admin_cidrs" {
  description = "List of CIDR blocks that can access the instances via SSH"
  type        = list(string)
  default     = ["123.4.5.19/32"] # Should be defined based on allowed ips in production!
}

variable "backend_port" {
  description = "Port that the backend API will listen on"
  type        = number
  default     = 8080
}