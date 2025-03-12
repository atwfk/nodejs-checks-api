#!/bin/bash

# Update and install dependencies
echo "Updating system and installing dependencies..."
apt update -y
apt install -y unzip docker.io

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
echo "AWS CLI installed."

# Start and enable Docker
echo "Starting Docker..."
systemctl start docker
systemctl enable docker
echo "Docker started and enabled."

# Start Docker container
echo "Starting Docker container..."
docker run -p 80:80 -p 443:443 -p 3002:3002 -p 3003:3003 -v ~/.aws:/root/.aws -e NODE_ENV=production ahmedtwfiek/checks-api:latest

echo "Docker container started."