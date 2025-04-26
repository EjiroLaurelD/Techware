variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "frontend_lb_dns_name" {
  description = "DNS name of the frontend load balancer"
  type        = string
}

variable "frontend_lb_zone_id" {
  description = "Zone ID of the frontend load balancer"
  type        = string
}

variable "backend_lb_dns_name" {
  description = "DNS name of the backend load balancer"
  type        = string
}

variable "backend_lb_zone_id" {
  description = "Zone ID of the backend load balancer"
  type        = string
}