#!/bin/bash

LAUNCH_TEMPLATE_ID="lt-079c3b57b594f0103"
INSTANCE_NAME="checks-api6"
SECURITY_GROUP_ID="sg-068f7965fec87eef9"

EXISTING_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ -n "$EXISTING_INSTANCE_ID" ]; then
    echo "An instance with the name '$INSTANCE_NAME' already exists with ID: $EXISTING_INSTANCE_ID"
    exit 1
fi

TEMPLATE_EXISTS=$(aws ec2 describe-launch-templates --query 'LaunchTemplates[*].LaunchTemplateId' --output text | grep -w "$LAUNCH_TEMPLATE_ID")

if [ -n "$TEMPLATE_EXISTS" ]; then
    echo "Launch template found with ID: $TEMPLATE_EXISTS"

    IMAGE_ID=$(aws ec2 describe-launch-template-versions \
        --launch-template-id $LAUNCH_TEMPLATE_ID \
        --query 'LaunchTemplateVersions[3].LaunchTemplateData.ImageId' \
        --output text)

    if [ -z "$IMAGE_ID" ]; then
        echo "Error: The launch template does not have an ImageId specified."
        exit 1
    else
        echo "Launch template uses AMI: $IMAGE_ID"
    fi

    echo "Launching EC2 instance with Security Group $SECURITY_GROUP_ID..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $IMAGE_ID \
        --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID,Version='$Latest' \
        --security-group-ids $SECURITY_GROUP_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    if [ -n "$INSTANCE_ID" ]; then
        echo "EC2 instance launched with ID: $INSTANCE_ID and name: $INSTANCE_NAME"
    else
        echo "Failed to launch EC2 instance."
    fi
else
    echo "Launch template with ID $LAUNCH_TEMPLATE_ID does not exist."
fi

