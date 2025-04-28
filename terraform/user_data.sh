# #!/bin/bash
# # Update and install Docker
# sudo yum update -y
# sudo amazon-linux-extras install docker
# sudo service docker start
# sudo usermod -a -G docker ec2-user

# # Log in to AWS ECR
# aws ecr get-login-password --region eu-west-2 | docker login --username ejiro --password-stdin 209479288101.dkr.ecr.eu-west-2.amazonaws.com

# # Pull the Docker image from ECR
# docker pull 209479288101.dkr.ecr.eu-west-2.amazonaws.com/frontend-app:01

# # Run the Docker container
# docker run -d -p 80:80 209479288101.dkr.ecr.eu-west-2.amazonaws.com/frontend-app:01

#!/bin/bash
# Update and install Docker
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install Nginx and OpenSSL for SSL termination
sudo amazon-linux-extras install nginx1 -y
sudo yum install -y openssl

# Create directory for SSL certificates
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/server.key \
  -out /etc/nginx/ssl/server.crt \
  -subj "/C=US/ST=State/L=City/O=Techware/CN=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"

# Configure Nginx with SSL and proxy to Docker container
sudo cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    
    location / {
        proxy_pass http://localhost:80;  # Docker container runs on port 80
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Log in to AWS ECR
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 209479288101.dkr.ecr.eu-west-2.amazonaws.com

# Pull the Docker image from ECR
docker pull 209479288101.dkr.ecr.eu-west-2.amazonaws.com/frontend-app:01

# Run the Docker container
# Note: We now run it on port 80 locally, and Nginx will proxy it
docker run -d -p 80:80 209479288101.dkr.ecr.eu-west-2.amazonaws.com/frontend-app:01

# Verify Nginx is working
sudo systemctl status nginx

# Log the completion
echo "Frontend setup with HTTPS completed: $(date)" > /tmp/setup-complete.log