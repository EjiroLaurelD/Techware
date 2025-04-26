/*
  Security Module: Creates security groups, IAM roles and policies
*/

# Security group for the frontend ALB
resource "aws_security_group" "frontend_alb" {
  name        = "${var.project_name}-frontend-alb-sg"
  description = "Security group for frontend application load balancer"
  vpc_id      = var.vpc_id

  # Allow incoming HTTP traffic from internet
  ingress {
    description      = "HTTP from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow incoming HTTPS traffic from internet
  ingress {
    description      = "HTTPS from internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow outgoing traffic to anywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.project_name}-frontend-alb-sg"
    Environment = var.environment
  }
}

# Security group for the frontend EC2 instances
resource "aws_security_group" "frontend_instance" {
  name        = "${var.project_name}-frontend-instance-sg"
  description = "Security group for frontend EC2 instances"
  vpc_id      = var.vpc_id

  # Allow incoming HTTP traffic from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb.id]
  }

  # Allow incoming HTTPS traffic from ALB only
  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb.id]
  }

  # Allow SSH from restricted IP ranges (bastion host would be better)
  ingress {
    description = "SSH from admin IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  # Allow outgoing traffic to anywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.project_name}-frontend-instance-sg"
    Environment = var.environment
  }
}

# Security group for the backend ALB
resource "aws_security_group" "backend_alb" {
  name        = "${var.project_name}-backend-alb-sg"
  description = "Security group for backend application load balancer"
  vpc_id      = var.vpc_id

  # Allow incoming HTTP/HTTPS traffic from frontend security group only
  ingress {
    description     = "HTTPS from frontend"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_instance.id]
  }

  ingress {
    description     = "HTTP from frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_instance.id]
  }

  # Allow outgoing traffic to anywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.project_name}-backend-alb-sg"
    Environment = var.environment
  }
}

# Security group for the ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow traffic from the backend ALB only
  ingress {
    description     = "Traffic from backend ALB"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb.id]
  }

  # Allow outgoing traffic to anywhere (for downloading dependencies, etc.)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-execution-role"
    Environment = var.environment
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Tasks (for the application itself)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = var.environment
  }
}

# IAM policy for the ECS task role with minimum required permissions
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.project_name}-ecs-task-policy"
  description = "Policy for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
      # Add other permissions as needed for your specific application
    ]
  })
}

# Attach the custom policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# EC2 Instance Profile for frontend instances
resource "aws_iam_instance_profile" "frontend_profile" {
  name = "${var.project_name}-frontend-profile"
  role = aws_iam_role.frontend_role.name
}

# IAM Role for EC2 Frontend Instances
resource "aws_iam_role" "frontend_role" {
  name = "${var.project_name}-frontend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-frontend-role"
    Environment = var.environment
  }
}

# Attach SSM policy to allow Session Manager access
resource "aws_iam_role_policy_attachment" "frontend_ssm" {
  role       = aws_iam_role.frontend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for frontend instances
resource "aws_iam_policy" "frontend_policy" {
  name        = "${var.project_name}-frontend-policy"
  description = "Policy for frontend EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }
      # Add other permissions as needed for your specific application
    ]
  })
}

# Attach the custom policy to the frontend role
resource "aws_iam_role_policy_attachment" "frontend_policy_attachment" {
  role       = aws_iam_role.frontend_role.name
  policy_arn = aws_iam_policy.frontend_policy.arn
}