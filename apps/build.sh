#!/bin/bash

# Define variables
AWS_REGION="eu-west-2"                  # Change to your AWS region
ECR_REPOSITORY="backend-app"    # Your ECR repository name
IMAGE_TAG="latest"                      # Tag for your image (can be dynamic, e.g., Git commit hash)
IMAGE_NAME="backend-app"                # Your Docker image name
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile ejiro)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

# Step 1: Log in to AWS ECR
echo "Logging into AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username ejiro --password-stdin $ECR_URI

# Step 2: Build the Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME .

# Step 3: Tag the image with ECR repository URI
echo "Tagging Docker image..."
docker tag $IMAGE_NAME:latest $ECR_URI:$IMAGE_TAG

# Step 4: Push the image to ECR
echo "Pushing Docker image to ECR..."
docker push $ECR_URI:$IMAGE_TAG

# Step 5: Optionally trigger ECS update to deploy the latest image (Optional)
# This part is for Fargate deployment; modify if you are using EC2-based ECS.
echo "Updating ECS service with new image..."
aws ecs update-service --cluster TechWare-prod-cluster --service TechWare-api-service --force-new-deployment --region $AWS_REGION
echo "Build and deployment complete!"
