#!/bin/bash

# create vpc 10.0.0.0/16

check_vpc=$(aws ec2 describe-vpcs --region eu-north-1 --filters Name=tag:Name,Values=devops90-vpc | grep -oP '(?<="VpcId": ")[^"]*')
if [ "$check_vpc" == "" ]; then

    vpc_result=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 --region eu-north-1 \
        --tag-specification ResourceType=vpc,Tags="[{Key=Name,Value=devops90-vpc}]" \
        --output json)
    echo $vpc_result

    vpc_id=$(echo $vpc_result | grep -oP '(?<="VpcId": ")[^"]*')
    echo $vpc_id

    if [ "$vpc_id" == "" ]; then
        echo "Error in creating the vpc"
        exit 1
    fi

    echo "VPC created."

else
    echo "VPC already exist"
    vpc_id=$check_vpc
    echo $vpc_id
fi


# ----------------------------------------------------------------------------

# create public subnet 10.0.1.0/24 in first az
# create public subnet 10.0.2.0/24 in second az
# create private subnet 10.0.3.0/24 in first az
# create private subnet 10.0.4.0/24 in second az

create_subnet()
{
    # $1 subnet number, $2 az, $3 public or private
    check_subnet=$(aws ec2 describe-subnets --region eu-north-1 --filters Name=tag:Name,Values=sub-$3-$1-devops90 | grep -oP '(?<="SubnetId": ")[^"]*')
    if [ "$check_subnet" == "" ]; then
        echo "subnet $1 will be created"

        subnet_result=$(aws ec2 create-subnet \
            --vpc-id $vpc_id --availability-zone eu-north-1$2 \
            --cidr-block 10.0.$1.0/24 \
            --tag-specifications ResourceType=subnet,Tags="[{Key=Name,Value=sub-$3-$1-devops90}]" --output json)
            
        echo $subnet_result

        subnet_id=$(echo $subnet_result | grep -oP '(?<="SubnetId": ")[^"]*')
        echo $subnet_id

        if [ "$subnet_id" == "" ]; then
            echo "Error in create subnet $1"
            exit 1
        fi
        echo "subnet $1 created."
    else
        echo "subnet $1 already exist"
        subnet_id=$check_subnet
        echo $subnet_id
    fi

}

create_subnet 1 a public
sub1_id=$subnet_id

create_subnet 2 b public
sub2_id=$subnet_id

create_subnet 3 a private
sub3_id=$subnet_id

create_subnet 4 b private
sub4_id=$subnet_id



# ----------------------------------------------------------------------------

# create internet gateway
check_igw=$(aws ec2 describe-internet-gateways  --filters Name=tag:Name,Values=devops90-igw | grep -oP '(?<="InternetGatewayId": ")[^"]*')
if [ "$check_igw" == "" ]; then
    echo "internet gateway will be created"

    igw_id=$(aws ec2 create-internet-gateway --region eu-north-1 \
        --tag-specifications ResourceType=internet-gateway,Tags="[{Key=Name,Value=devops90-igw}]" --output json | grep -oP '(?<="InternetGatewayId": ")[^"]*')

    if [ "$igw_id" == "" ]; then
        echo "Error in create internet gateway"
        exit 1
    fi
    echo "internet gateway created."
    
else
    echo "internet gateway already exist"
    igw_id=$check_igw
fi

echo $igw_id

# Attach the internet gateway to vpc (no output)

igw_attach=$(aws ec2 describe-internet-gateways --internet-gateway-ids $igw_id | grep -oP '(?<="VpcId": ")[^"]*')
if [ "$igw_attach" != "$vpc_id" ]; then
    attach_result=$(aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id)
    if [ "$attach_result" == "" ]; then
        echo "internet gateway attached to the vpc"
    else 
        echo "Internet gateway AlreadyAssociated"
    fi
else
    echo "Internet gateway already attached to this vpc"
fi
# ----------------------------------------------------------------------------

# create public rout table
check_rtb=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=public-devops90-rtb | grep -oP '(?<="RouteTableId": ")[^"]*' | uniq)

if [ "$check_rtb" == "" ]; then
    echo "public route table will be created"
    public_rtb_id=$(aws ec2 create-route-table --vpc-id $vpc_id --tag-specifications ResourceType=route-table,Tags="[{Key=Name,Value=public-devops90-rtb}]"  --output json | grep -oP '(?<="RouteTableId": ")[^"]*'  | uniq)
    if [ "$public_rtb_id" == "" ]; then
        echo "Error in create public route table"
        exit 1
    fi
    echo "public route table created."

    # create public route 
    route_result=$(aws ec2 create-route --route-table-id $public_rtb_id \
        --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id | grep -oP '(?<="Return": ")[^"]*')
    echo $route_result
    if [ "$route_result" != "true" ]; then
        echo "public route creation faild"
        exit 1
    fi
    echo "public route created"

else 
    echo "public route table already exist"
    public_rtb_id=$check_rtb
fi

echo $public_rtb_id


# associate public route table to the public subnets
aws ec2 associate-route-table --route-table-id $public_rtb_id --subnet-id $sub1_id
aws ec2 associate-route-table --route-table-id $public_rtb_id --subnet-id $sub2_id

# ----------------------------------------------------------------------------

# create private route table
check_rtb=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-devops90-rtb | grep -oP '(?<="RouteTableId": ")[^"]*'  | uniq)
if [ "$check_rtb" == "" ]; then
    echo "private route table will be created"
    private_rtb_id=$(aws ec2 create-route-table --vpc-id $vpc_id --tag-specifications ResourceType=route-table,Tags="[{Key=Name,Value=private-devops90-rtb}]"  --output json | grep -oP '(?<="RouteTableId": ")[^"]*'  | uniq)
    
    if [ "$private_rtb_id" == "" ]; then
        echo "Error in create private route table"
        exit 1
    fi
    echo "private route table created."

else 
    echo "private route table already exist"
    private_rtb_id=$check_rtb
fi

echo $private_rtb_id

# associate public route table to the public subnets
aws ec2 associate-route-table --route-table-id $private_rtb_id --subnet-id $sub3_id
aws ec2 associate-route-table --route-table-id $private_rtb_id --subnet-id $sub4_id
# ----------------------------------------------------------------------------







# ---------------------------------------------------------------------------- SUGGESTIONS ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# create security group
check_sg=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=devops90-sg | grep -oP '(?<="GroupId": ")[^"]*')
if [ "$check_sg" == "" ]; then
    echo "security group will be created"
    sg_id=$(aws ec2 create-security-group --group-name devops90-sg --description "devops90-sg" --vpc-id $vpc_id --tag-specifications ResourceType=security-group,Tags="[{Key=Name,Value=devops90-sg}]" --output json | grep -oP '(?<="GroupId": ")[^"]*')
    if [ "$sg_id" == "" ]; then
        echo "Error in create security group"
        exit 1
    fi
    echo "security group created."
else
    echo "security group already exist"
    sg_id=$check_sg
fi

echo $sg_id
# ----------------------------------------------------------------------------
# add ingress rules to the security group
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 80 --cidr
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 443 --cidr
# ----------------------------------------------------------------------------
# add egress rules to the security group
aws ec2 authorize-security-group-egress --group-id $sg_id --protocol tcp --port 22 --cidr
aws ec2 authorize-security-group-egress --group-id $sg_id --protocol tcp --port 80 --cidr
aws ec2 authorize-security-group-egress --group-id $sg_id --protocol tcp --port 443 --cidr
# ----------------------------------------------------------------------------
# create key pair
check_key=$(aws ec2 describe-key-pairs --key-names devops90-key | grep -oP '(?<="KeyName": ")[^"]*')    
if [ "$check_key" == "" ]; then
    echo "key pair will be created"
    key_result=$(aws ec2 create-key-pair --key-name devops90-key --query 'KeyMaterial' --output text > devops90-key.pem)
    if [ "$key_result" == "" ]; then
        echo "Error in create key pair"
        exit 1
    fi
    echo "key pair created."
else
    echo "key pair already exist"
fi
# ----------------------------------------------------------------------------
# create nat gateway
check_nat=$(aws ec2 describe-nat-gateways --filter Name=tag:Name,Values=devops90-nat | grep -oP '(?<="NatGatewayId": ")[^"]*')  
if [ "$check_nat" == "" ]; then
    echo "nat gateway will be created"
    nat_result=$(aws ec2 create-nat-gateway --subnet-id $sub1_id --allocation-id eipalloc-0c2e7b3b7e7b3e7b3 --tag-specifications ResourceType=natgateway,Tags="[{Key=Name,Value=devops90-nat}]" --output json)
    if [ "$nat_result" == "" ]; then
        echo "Error in create nat gateway"
        exit 1
    fi
    echo "nat gateway created."
else
    echo "nat gateway already exist"
fi
# ----------------------------------------------------------------------------
# create elastic ip
check_eip=$(aws ec2 describe-addresses --filter Name=tag:Name,Values=devops90-eip | grep -oP '(?<="AllocationId": ")[^"]*') 
if [ "$check_eip" == "" ]; then
    echo "elastic ip will be created"
    eip_result=$(aws ec2 allocate-address --domain vpc --tag-specifications ResourceType=elastic-ip,Tags="[{Key=Name,Value=devops90-eip}]" --output json)
    if [ "$eip_result" == "" ]; then
        echo "Error in create elastic ip"
        exit 1
    fi
    echo "elastic ip created."
else
    echo "elastic ip already exist"
fi
# ----------------------------------------------------------------------------
# associate elastic ip with nat gateway
eip_associate=$(aws ec2 describe-addresses --allocation-ids eipalloc-0c2e7b3b7e7b3e7b3 | grep -oP '(?<="AssociationId": ")[^"]*')   
if [ "$eip_associate" == "" ]; then
    echo "elastic ip will be associated with nat gateway"
    eip_associate_result=$(aws ec2 associate-address --allocation-id eipalloc-0c2e7b3b7e7b3e7b3 --nat-gateway-id nat-0c2e7b3b7e7b3e7b3)
    if [ "$eip_associate_result" == "" ]; then
        echo "Error in associate elastic ip with nat gateway"
        exit 1
    fi
    echo "elastic ip associated with nat gateway."
else
    echo "elastic ip already associated with nat gateway"
fi
# ----------------------------------------------------------------------------
