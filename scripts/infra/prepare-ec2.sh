# mount ebs volume
lsblk
sudo nvme list

sudo mkfs -t ext4 /dev/xvdb
sudo mkdir -p /mnt/ebs
sudo mount /dev/xvdb /mnt/ebs
df -h

#install aws
sudo snap install aws-cli --classic

# install docker 
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

export TWILIO_ACCOUNT_SID=$(aws ssm get-parameter --name CHECKS_API_TWILIO_ACCOUNT_SID --with-decryption --query "Parameter.Value" --output text)
export TWILIO_AUTH_TOKEN=$(aws ssm get-parameter --name CHECKS_API_TWILIO_AUTH_TOKEN --with-decryption --query "Parameter.Value" --output text)
echo $TWILIO_ACCOUNT_SID
echo $TWILIO_AUTH_TOKEN

docker run -p 3002:3002 -p 3003:3003 \                                                 
  -e CHECKS_API_TWILIO_ACCOUNT_SID=$(aws ssm get-parameter --name CHECKS_API_TWILIO_ACCOUNT_SID --with-decryption --query "Parameter.Value" --output text) \
  -e CHECKS_API_TWILIO_AUTH_TOKEN=$(aws ssm get-parameter --name CHECKS_API_TWILIO_AUTH_TOKEN --with-decryption --query "Parameter.Value" --output text) \
  checks-api

docker run -p 3002:3002 -p 3003:3003 \
  -e CHECKS_API_TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID \
  -e CHECKS_API_TWILIO_AUTH_TOKEN=$TWILIO_AUTH_TOKEN \
  ahmedtwfiek/checks-api:latest
