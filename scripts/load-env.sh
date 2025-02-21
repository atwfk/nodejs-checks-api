#!/bin/bash

touch /app/.env 
echo "ACCOUNT_SID=${CHECKS_API_TWILIO_ACCOUNT_SID}" >> /app/.env
echo "AUTH_TOKEN=${CHECKS_API_TWILIO_AUTH_TOKEN}" >> /app/.env

echo "Environment variables written to .env file."
