#!/bin/bash
# Frontend Deployment Script

set -e

# Build the frontend application
echo "Building frontend application..."
npm run build

# Copy files to the web server directory
echo "Copying files to web server directory..."
cp -r dist/* /var/www/html/

# Set proper permissions
echo "Setting permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache
echo "Restarting web server..."
systemctl restart httpd

echo "Frontend deployment completed successfully."