# Cloud-Native Architecture on AWS

This project implements a secure, scalable, and production-ready cloud-native architecture on AWS that supports both backend services (running in ECS Fargate) and a frontend application (running on EC2 instances).

## Architecture Overview

![Architecture Diagram](architecture_diagram.png)

The architecture consists of the following components:

1. **Network Layer**
   - VPC with public and private subnets across multiple Availability Zones
   - Internet Gateway for public internet access
   - NAT Gateways for outbound internet access from private subnets
   - Route tables, VPC Flow Logs, and security groups for network security

2. **Backend Services**
   - ECS Fargate cluster for running containerized microservices
   - REST API sample application deployed as a Fargate task
   - Internal Application Load Balancer for backend services
   - Auto-scaling capabilities based on demand

3. **Frontend Application**
   - EC2 instances in a public subnet running the React frontend application
   - Auto Scaling Group for high availability and scalability
   - Public Application Load Balancer for frontend traffic
   - CloudWatch alarms and metrics for monitoring

4. **Security Measures**
   - Network segmentation with public and private subnets
   - Security groups with least privilege access
   - IAM roles and policies with specific permissions
   - HTTPS/TLS encryption for all traffic
   - Internal-only access to backend services

5. **DNS Configuration**
   - Custom domain setup with Route53
   - SSL certificates for secure communication
   - A-records for frontend and backend applications

## Security Implementation

### Network-level Security
- VPC Flow Logs to monitor network traffic
- Security Groups with strict ingress/egress rules
- Private subnets for backend services
- NAT Gateways for secure outbound internet access

### Application-level Security
- HTTPS/TLS encryption for all communication
- IAM roles with least privilege
- SSL certificates for frontend and backend endpoints
- Secure communication between frontend and backend via internal DNS

## High Availability and Fault Tolerance
- Resources deployed across multiple Availability Zones
- Auto Scaling for frontend and backend components
- Load balancers to distribute traffic
- Health checks and self-healing infrastructure

## Infrastructure as Code
- Terraform modules for reusable and modular infrastructure
- Environment-specific configurations
- Secure state management with S3 and DynamoDB

## Deployment Instructions

### Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform v1.0.0 or later
3. A registered domain name (for custom domain setup)
4. Docker installed (for building backend container image)

### Deployment Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/your-username/cloud-native-aws.git
   cd cloud-native-aws
   ```

2. **Build and push the backend Docker image**
   ```bash
   cd apps/backend
   docker build -t cloud-native-backend:latest .
   
   # Tag and push to your ECR repository
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
   docker tag cloud-native-backend:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/cloud-native-backend:latest
   docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/cloud-native-backend:latest
   ```

3. **Create an S3 bucket and DynamoDB table for Terraform state**
   ```bash
   aws s3 mb s3://terraform-state-cloud-native-demo-dev
   
   aws dynamodb create-table \
       --table-name terraform-locks-cloud-native-demo-dev \
       --attribute-definitions AttributeName=LockID,AttributeType=S \
       --key-schema AttributeName=LockID,KeyType=HASH \
       --billing-mode PAY_PER_REQUEST
   ```

4. **Update Terraform variables**
   
   Edit `terraform/environments/dev/terraform.tfvars`:
   ```hcl
   project_name      = "cloud-native-demo"
   environment       = "dev"
   aws_region        = "us-east-1"
   domain_name       = "your-domain.com"
   api_image         = "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/cloud-native-backend:latest"
   ```

5. **Initialize and apply Terraform**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

6. **Verify the deployment**
   ```bash
   # Check ECS service status
   aws ecs describe-services --cluster cloud-native-demo-dev-cluster --services cloud-native-demo-dev-api
   
   # Check EC2 instances
   aws ec2 describe-instances --filters "Name=tag:Name,Values=cloud-native-demo-dev-frontend"
   ```

7. **Access the application**
   
   Once deployment is complete, you can access the frontend at:
   ```
   https://app.your-domain.com
   ```

   The backend API will be available at:
   ```
   https://api.your-domain.com
   ```

## Frontend-Backend Communication

The frontend application communicates with the backend services through the following mechanism:

1. The frontend EC2 instances are configured with the backend API endpoint during launch:
   ```
   https://api.your-domain.com
   ```

2. The API endpoint is internal to the VPC but has a DNS record in Route53.

3. All communication uses HTTPS with TLS encryption.

4. CORS is configured on the backend to accept requests only from the frontend domain.

5. The frontend uses Axios to make API calls to the backend endpoints:
   ```javascript
   const API_URL = import.meta.env.VITE_API_URL || 'https://api.your-domain.com';
   const response = await axios.get(`${API_URL}/api/v1/items`);
   ```

## Monitoring and Maintenance

### Monitoring
- CloudWatch metrics for ECS, EC2, and load balancers
- CloudWatch alarms for CPU, memory, and other critical metrics
- VPC Flow Logs for network monitoring
- CloudWatch Logs for application logging

### Scaling
- Auto Scaling policies based on CPU utilization
- ECS service scaling based on demand
- Load balancer health checks for instance replacement

### Maintenance
- Use the ECS console or CLI for backend updates:
  ```bash
  aws ecs update-service --cluster cloud-native-demo-dev-cluster --service cloud-native-demo-dev-api --force-new-deployment
  ```

- For frontend updates, deploy new code via SSH or user data script:
  ```bash
  # SSH to instance and run deployment script
  ssh ec2-user@instance-ip "cd /var/www/html/app && ./deploy.sh"
  ```

## Future Improvements

1. Implement CI/CD pipeline with AWS CodePipeline or GitHub Actions
2. Add AWS WAF for additional security
3. Implement AWS X-Ray for distributed tracing
4. Add AWS Secrets Manager for sensitive configuration
5. Implement database tier (RDS or DynamoDB)# Techware
