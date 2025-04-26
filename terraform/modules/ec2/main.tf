/*
  Frontend Module: Creates EC2 instances, Auto Scaling Group, and Load Balancer for the frontend
*/

# AMI data source (Amazon Linux 2)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for EC2 instances
locals {
  user_data = <<-EOT
#!/bin/bash
# Update packages
yum update -y

# Install necessary packages
yum install -y httpd git

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Install Node.js and npm
curl -sL https://rpm.nodesource.com/setup_16.x | bash -
yum install -y nodejs

# Clone and set up the frontend application
mkdir -p /var/www/html/app
cd /var/www/html/app

# Add application setup here
# This is a placeholder; you'd typically clone your frontend app from a repository
echo "<html><body><h1>Frontend Application</h1><p>API Endpoint: ${var.api_endpoint}</p></body></html>" > /var/www/html/index.html

# Configure the application to communicate with the backend
cat > /var/www/html/app/config.js <<EOF
const API_ENDPOINT = '${var.api_endpoint}';
export default API_ENDPOINT;
EOF

# Set file permissions
chown -R apache:apache /var/www/html

# Install CloudWatch agent for logs and metrics
yum install -y amazon-cloudwatch-agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "${var.project_name}-${var.environment}-frontend-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "${var.project_name}-${var.environment}-frontend-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["*"],
        "drop_device": true
      },
      "mem": {
        "measurement": ["mem_used_percent"]
      }
    },
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    }
  }
}
EOF

# Start the CloudWatch agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
EOT
}

# CloudWatch Log Group for EC2 instances
resource "aws_cloudwatch_log_group" "frontend_access" {
  name              = "${var.project_name}-${var.environment}-frontend-access"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-frontend-access-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "frontend_error" {
  name              = "${var.project_name}-${var.environment}-frontend-error"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-frontend-error-logs"
    Environment = var.environment
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "frontend" {
  name_prefix            = "${var.project_name}-${var.environment}-frontend-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.frontend_instance_sg_id]
  user_data              = base64encode(local.user_data)

  iam_instance_profile {
    name = var.frontend_instance_profile_name
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-frontend"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for frontend
resource "aws_autoscaling_group" "frontend" {
  name_prefix               = "${var.project_name}-${var.environment}-frontend-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = false
  wait_for_capacity_timeout = "10m"

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = {
      Name        = "${var.project_name}-${var.environment}-frontend",
      Environment = var.environment
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB for frontend
resource "aws_lb" "frontend" {
  name               = "${var.project_name}-${var.environment}-frontend"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [var.frontend_alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name        = "${var.project_name}-frontend-alb"
    Environment = var.environment
  }
}

# Target group for frontend ALB
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-${var.environment}-frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.project_name}-frontend-target-group"
    Environment = var.environment
  }
}

# Attach ASG to target group
resource "aws_autoscaling_attachment" "frontend" {
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  lb_target_group_arn    = aws_lb_target_group.frontend.arn
}

# HTTP listener for frontend ALB
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener for frontend ALB
resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-frontend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors EC2 high CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-frontend-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "This alarm monitors EC2 low CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-frontend-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-frontend-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}