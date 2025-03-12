#!/bin/bash

# Install AWS CLI (if not already installed)
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI..."
  apk add --no-cache aws-cli
fi

# Create the https directory if it doesn't exist
mkdir -p ./https

# Download the certificate and private key from S3
echo "Downloading SSL certificates from S3..."
if ! aws s3 cp s3://checks-app/certificate/private-key.pem ./https/key.pem; then
  echo "Error: Failed to download private-key.pem from S3"
  exit 1
fi

if ! aws s3 cp s3://checks-app/certificate/certificate.pem ./https/cert.pem; then
  echo "Error: Failed to download certificate.pem from S3"
  exit 1
fi

echo "SSL certificates downloaded."