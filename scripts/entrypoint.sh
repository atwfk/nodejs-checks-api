#!/bin/sh

NODE_ENV=${NODE_ENV:-production}
echo "Running in ${NODE_ENV} mode..."

# export AWS_PROFILE=learning

echo "Checking AWS configuration..."
aws configure list

echo "Generating SSL certificates..."
sh ./scripts/generate-certificates.sh

echo "Creating .env file..."
sh ./scripts/load-env.sh

echo "Starting Nginx..."
nginx

echo "Starting the application..."
pm2-runtime start ./index.js
