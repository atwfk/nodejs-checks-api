#!/bin/bash

fetch_ssm_parameter() {
  local param_name=$1
  local max_retries=3
  local retry_count=0

  while [ $retry_count -lt $max_retries ]; do
    if value=$(aws ssm get-parameter --name "$param_name" --query "Parameter.Value" --output text --with-decryption); then
      echo "$value"
      return 0
    else
      retry_count=$((retry_count + 1))
      echo "Retrying ($retry_count/$max_retries) to fetch $param_name..."
      sleep 2
    fi
  done

  echo "Error: Failed to fetch $param_name after $max_retries retries"
  return 1
}

echo "Fetching environment variables from SSM Parameter Store..."

if ! CHECKS_API_TWILIO_ACCOUNT_SID=$(fetch_ssm_parameter "CHECKS_API_TWILIO_ACCOUNT_SID"); then
  exit 1
else
  echo "Successfully fetched CHECKS_API_TWILIO_ACCOUNT_SID"
fi

if ! CHECKS_API_TWILIO_AUTH_TOKEN=$(fetch_ssm_parameter "CHECKS_API_TWILIO_AUTH_TOKEN"); then
  exit 1
else
  echo "Successfully fetched CHECKS_API_TWILIO_AUTH_TOKEN"
fi

echo "Writing environment variables to .env file..."
cat <<EOF > ./.env
ACCOUNT_SID=${CHECKS_API_TWILIO_ACCOUNT_SID}
AUTH_TOKEN=${CHECKS_API_TWILIO_AUTH_TOKEN}
EOF

echo "Environment variables written to .env file."