terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = "ejiro"
}

# Configure backend for state
terraform {
  backend "s3" {
    bucket         = "techware-tfstate"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "techware-tf-lock"
    profile = "ejiro"

  }
}

# Add this to your main.tf
resource "tls_private_key" "domain" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "domain" {
  private_key_pem = tls_private_key.domain.private_key_pem
  
  subject {
    common_name  = "ejiro.com"  # Can be any domain, doesn't need to be real
    organization = "Techware Organization"
  }
  
  validity_period_hours = 8760  # 1 year
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self_signed" {
  private_key      = tls_private_key.domain.private_key_pem
  certificate_body = tls_self_signed_cert.domain.cert_pem
}


# Networking module
module "networking" {
  source = "./modules/networking"

  project_name      = var.project_name
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
}

# Security module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  admin_cidrs  = var.admin_cidrs
  backend_port = var.backend_port
}

# ECS module
module "ecs" {
  source = "./modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn         = module.security.ecs_task_role_arn
  backend_alb_sg_id         = module.security.backend_alb_sg_id
  ecs_tasks_sg_id           = module.security.ecs_tasks_sg_id
  api_image                 = var.api_image
  api_port                  = var.backend_port
  api_cpu                   = var.api_cpu
  api_memory                = var.api_memory
  api_desired_count         = var.api_desired_count
  health_check_path         = var.health_check_path
  #api_certificate_arn       = module.dns.backend_certificate_arn
}

# Frontend module
module "frontend" {
  source = "./modules/frontend"

  project_name                  = var.project_name
  environment                   = var.environment
  vpc_id                        = module.networking.vpc_id
  public_subnet_ids             = module.networking.public_subnet_ids
  frontend_alb_sg_id            = module.security.frontend_alb_sg_id
  frontend_instance_sg_id       = module.security.frontend_instance_sg_id
  frontend_instance_profile_name = module.security.frontend_instance_profile_name
  api_endpoint                  = "https://backend"
  instance_type                 = var.instance_type
  min_size                      = var.min_size
  max_size                      = var.max_size
  desired_capacity              = var.desired_capacity
  certificate_arn = aws_acm_certificate.self_signed.arn

  # certificate_arn               = module.dns.frontend_certificate_arn
}

# DNS module
# module "dns" {
#   source = "./modules/dns"

#   project_name         = var.project_name
#   environment          = var.environment
#   domain_name          = var.domain_name
#   frontend_lb_dns_name = module.frontend.frontend_lb_dns_name
#   frontend_lb_zone_id  = module.frontend.frontend_lb_zone_id
#   backend_lb_dns_name  = module.ecs.api_lb_dns_name
#   backend_lb_zone_id   = module.ecs.api_lb_zone_id
# }