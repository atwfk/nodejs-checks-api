# Use official Node.js Alpine image
FROM node:18-alpine
ENV NODE_ENV="production"
# Set the working directory inside the container
WORKDIR /app

# Install OpenSSL (Required for SSL certificate generation)
RUN apk add --no-cache openssl


# Copy the application files
COPY . .

# Install PM2 globally
RUN npm install -g pm2

# Make scripts executable
RUN chmod +x /app/scripts/load-env.sh /app/scripts/generate-certificates.sh /app/scripts/entrypoint.sh

# Expose required ports
EXPOSE 3002 3003

# Run the scripts and start the application using PM2
ENTRYPOINT ["/bin/sh", "/app/scripts/entrypoint.sh"]
