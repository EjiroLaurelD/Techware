/*
  ECS Module: Creates an ECS cluster, task definitions, and services
*/

# ECR Repository for Backend Application
resource "aws_ecr_repository" "backend_repo" {
  name                 = "${var.environment}-backend-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_ecs_service" "api" {
  name                               = "${var.project_name}-${var.environment}-api"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.api.arn
  desired_count                      = var.api_desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = 60
  enable_execute_command             = true  # Enable ECS Exec for debugging

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${var.project_name}-api"
    container_port   = var.api_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  tags = {
    Name        = "${var.project_name}-api-service"
    Environment = var.environment
  }

  # # Added lifecycle block to prevent accidental deletion
  # lifecycle {
  #   prevent_destroy = "prod" ? true : false
  # }
}
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-ecs-cluster"
    Environment = var.environment
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# CloudWatch Log Group for API service
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}-${var.environment}-api"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-api-logs"
    Environment = var.environment
  }
}

# ECS Task Definition for API service
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-${var.environment}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name         = "${var.project_name}-api"
      image        = var.api_image
      essential    = true
      portMappings = [
        {
          containerPort = var.api_port
          hostPort      = var.api_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.api_port)
        }
        # Add other environment variables as needed
      ]
      secrets = []  # Add secrets from Parameter Store/Secrets Manager if needed
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-api-task"
    Environment = var.environment
  }
}

# ALB for the API service
resource "aws_lb" "api" {
  name               = "${var.project_name}-${var.environment}-api-alb"
  internal           = true  # Internal ALB, not exposed to the internet
  load_balancer_type = "application"
  security_groups    = [var.backend_alb_sg_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name        = "${var.project_name}-api-alb"
    Environment = var.environment
  }
}

# Target group for the API ALB
resource "aws_lb_target_group" "api" {
  name        = "${var.project_name}-${var.environment}-api-tg"
  port        = var.api_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  deregistration_delay = "5"


  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-api-target-group"
    Environment = var.environment
  }
  
}

# Listener for the API ALB
resource "aws_lb_listener" "api_http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
   
}

#Optional HTTPS listener with SSL certificate
resource "aws_lb_listener" "api_https" {
  count             = var.api_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.api_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# ECS Service for API
# resource "aws_ecs_service" "api" {
#   name                               = "${var.project_name}-${var.environment}-api"
#   cluster                            = aws_ecs_cluster.main.id
#   task_definition                    = aws_ecs_task_definition.api.arn
#   desired_count                      = var.api_desired_count
#   launch_type                        = "FARGATE"
#   platform_version                   = "LATEST"
#   health_check_grace_period_seconds  = 60
#   enable_execute_command             = true  # Enable ECS Exec for debugging

#   network_configuration {
#     subnets          = var.private_subnet_ids
#     security_groups  = [var.ecs_tasks_sg_id]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.api.arn
#     container_name   = "${var.project_name}-api"
#     container_port   = var.api_port
#   }

#   deployment_circuit_breaker {
#     enable   = true
#     rollback = true
#   }

#   deployment_controller {
#     type = "ECS"
#   }

#   tags = {
#     Name        = "${var.project_name}-api-service"
#     Environment = var.environment
#   }
# }