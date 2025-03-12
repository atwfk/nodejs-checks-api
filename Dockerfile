# Use official Node.js Alpine image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Install OpenSSL, AWS CLI, and Nginx
RUN apk add --no-cache openssl aws-cli nginx

# Copy the application files
COPY . .

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/http.d/default.conf

# Install PM2 globally
RUN npm install -g pm2

# Make scripts executable
RUN chmod +x /app/scripts/load-env.sh /app/scripts/generate-certificates.sh /app/scripts/entrypoint.sh

# Expose required ports
EXPOSE 80 3002 3003

# Run the scripts and start the application using PM2
ENTRYPOINT ["/bin/sh", "/app/scripts/entrypoint.sh"]