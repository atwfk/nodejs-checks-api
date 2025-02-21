#!/bin/sh

echo "Running pre-start scripts..."

cd scripts

echo "Generating SSL certificates..."
sh generate-certificates.sh

echo "Creating .env file..."
sh load-env.sh

echo "Starting the application..."
pm2-runtime start ../index.js
