#!/bin/bash

LAUNCH_TEMPLATE_ID="lt-03f793155241830cb"
INSTANCE_NAME="checks-api"

check_instance_state() {
    local instance_id=$1
    state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[*].Instances[*].State.Name' --output text)
    echo "$state"
}

EXISTING_INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ -n "$EXISTING_INSTANCE_IDS" ]; then
    echo "Instances with the name '$INSTANCE_NAME' already exist with IDs: $EXISTING_INSTANCE_IDS"

    for instance_id in $EXISTING_INSTANCE_IDS; do
        state=$(check_instance_state "$instance_id")
        echo "Instance ID: $instance_id, State: $state"

        if [ "$state" == "running" ]; then
            echo "A running instance already exists. Exiting."
            exit 1
        fi
    done

    echo "All instances are terminated. Proceeding to launch a new instance."
fi

TEMPLATE_EXISTS=$(aws ec2 describe-launch-templates \
    --launch-template-ids "$LAUNCH_TEMPLATE_ID" \
    --query 'LaunchTemplates[*].LaunchTemplateId' \
    --output text)

if [ -z "$TEMPLATE_EXISTS" ]; then
    echo "Launch template with ID $LAUNCH_TEMPLATE_ID does not exist."
    exit 1
fi

echo "Launch template found with ID: $TEMPLATE_EXISTS"

echo "Launching EC2 instance with Launch Template $LAUNCH_TEMPLATE_ID..."
INSTANCE_ID=$(aws ec2 run-instances \
    --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID,Version='$Latest' \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -n "$INSTANCE_ID" ]; then
    echo "EC2 instance launched with ID: $INSTANCE_ID and name: $INSTANCE_NAME"
else
    echo "Failed to launch EC2 instance."
    exit 1
fi