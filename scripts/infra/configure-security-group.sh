aws ec2 create-security-group \
    --group-name SSH-Tunnel-SG \
    --description "Security group for SSH tunneling" \
    --query 'GroupId'
    --output text

aws ec2 authorize-security-group-ingress \
    --group-id sg-0abcd1234efgh5678 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 create-launch-template-version \
    --launch-template-id lt-079c3b57b594f0103 \
    --version-description "Added SSH Tunnel Security Group" \
    --launch-template-data '{"NetworkInterfaces":[{"DeviceIndex":0,"Groups":["sg-068f7965fec87eef9"]}]}'

aws ec2 authorize-security-group-ingress \
    --group-id sg-0abcd1234efgh5678 \
    --protocol tcp \
    --port 3002 \
    --cidr 0.0.0.0/0