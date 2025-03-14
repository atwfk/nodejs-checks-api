#!/bin/bash

region="ca-central-1"
dns_name="atwfk.link"

create_hosted_zone() {
    check_zone=$(aws route53 list-hosted-zones-by-name --dns-name "$dns_name" | jq -r '.HostedZones[] | select(.Name == "'"$dns_name".'") | .Id')
    if [ -z "$check_zone" ]; then
        echo "Hosted Zone will be created ..."
        time=$(date -u +"%Y-%m-%d-%H-%M-%S")
        hosted_zone_id=$(aws route53 create-hosted-zone --name "$dns_name" --caller-reference "$time" | jq -r '.HostedZone.Id')
        
        if [ -z "$hosted_zone_id" ]; then
            echo "Error in create Hosted Zone"
            exit 1
        fi
        echo "Hosted Zone created."
    else
        echo "Hosted Zone already exists."
        hosted_zone_id="$check_zone"
    fi
}

get_instance_ip() {
    # $1 ec2 Name
    ec2_ip=$(aws ec2 describe-instances --region "$region" \
        --filters "Name=tag:Name,Values=$1" "Name=instance-state-name,Values=running" \
        | jq -r '.Reservations[].Instances[].PublicIpAddress')
    
    if [ -z "$ec2_ip" ]; then
        echo "No running EC2 instance found with name: '$1'."
        exit 1
    else
        echo "EC2 found. Public IP: $ec2_ip"
    fi
}

create_dns_record() {
    # $1 sub domain, $2 ip
    full_sub_domain="$1.$dns_name"
    change=$(cat << EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$full_sub_domain",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$2"
          }
        ]
      }
    }
  ]
}
EOF
)

    check_record=$(aws route53 list-resource-record-sets --hosted-zone-id "$hosted_zone_id" --query "ResourceRecordSets[?Name == '$full_sub_domain.']" | jq -r '.[].Name')
    if [ -z "$check_record" ]; then
        echo "DNS Record will be created ..."
        record_id=$(aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone_id" --change-batch "$change" | jq -r '.ChangeInfo.Id')
        
        if [ -z "$record_id" ]; then
            echo "Error in creating DNS Record"
            exit 1
        fi
        echo "DNS Record created."
    else
        echo "DNS Record already exists. Updating..."
        record_id=$(aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone_id" --change-batch "$change" | jq -r '.ChangeInfo.Id')
        
        if [ -z "$record_id" ]; then
            echo "Error in updating DNS Record"
            exit 1
        fi
        echo "DNS Record updated."
    fi
}

create_hosted_zone
get_instance_ip "checks-api"
create_dns_record "checks" "$ec2_ip"