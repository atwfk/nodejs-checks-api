#!/bin/bash

mkdir https

if [ ! -f "https/key.pem" ] || [ ! -f "https/cert.pem" ]; then
  openssl req -newkey rsa:2048 -nodes -keyout https/key.pem -x509 -days 365 -out https/cert.pem -subj "/C=US/ST=State/L=City/O=Company/OU=IT/CN=example.com"
  echo "SSL certificates generated."
else
  echo "SSL certificates already exist."
fi
