#!/bin/bash

# Variables
STACK_NAME="MainStack"
ROUTE_STACK_NAME="RouteStack"
S3_BUCKET="sirwan-lab-v1"
REGION="eu-west-2"  # Change this to your AWS region
LOG_FILE="deployment.log"

# Determine script location and set template directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# Ensure the template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template directory $TEMPLATE_DIR not found!" | tee -a $LOG_FILE
    exit 1
fi

# Template file locations
TEMPLATES=("$TEMPLATE_DIR/main.yaml" "$TEMPLATE_DIR/s3.yaml" "$TEMPLATE_DIR/vpc.yaml" "$TEMPLATE_DIR/subnet.yaml" "$TEMPLATE_DIR/route.yaml")

# Function to check if S3 bucket exists
check_s3_bucket() {
    if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
        echo "S3 bucket $S3_BUCKET exists." | tee -a $LOG_FILE
    else
        echo "S3 bucket $S3_BUCKET does not exist. Creating it..." | tee -a $LOG_FILE
        aws s3api create-bucket --bucket "$S3_BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
    fi
}

# Function to upload templates to S3
upload_templates() {
    echo "Uploading CloudFormation templates from $TEMPLATE_DIR to S3..." | tee -a $LOG_FILE
    for template in "${TEMPLATES[@]}"; do
        if [ -f "$template" ]; then
            aws s3 cp "$template" "s3://$S3_BUCKET/" | tee -a $LOG_FILE
            echo "Uploaded $(basename "$template") to s3://$S3_BUCKET/" | tee -a $LOG_FILE
        else
            echo "Error: Template file $(basename "$template") not found in $TEMPLATE_DIR!" | tee -a $LOG_FILE
            exit 1
        fi
    done
}

# Function to check if a stack exists
stack_exists() {
    aws cloudformation describe-stacks --stack-name "$1" --region "$REGION" > /dev/null 2>&1
    return $?
}

# Function to deploy or update CloudFormation stack
deploy_stack() {
    TEMPLATE_URL="https://s3.$REGION.amazonaws.com/$S3_BUCKET/main.yaml"

    echo "Starting deployment of stack: $STACK_NAME" | tee -a $LOG_FILE

    if stack_exists "$STACK_NAME"; then
        echo "Stack already exists. Updating..." | tee -a $LOG_FILE
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-url "$TEMPLATE_URL" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" 2>&1 | tee -a $LOG_FILE

        echo "Waiting for stack update to complete..." | tee -a $LOG_FILE
        aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$REGION"
    else
        echo "Stack does not exist. Creating..." | tee -a $LOG_FILE
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-url "$TEMPLATE_URL" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" 2>&1 | tee -a $LOG_FILE

        echo "Waiting for stack creation to complete..." | tee -a $LOG_FILE
        aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"
    fi

    echo "Waiting for SubnetStack creation to complete..." | tee -a $LOG_FILE
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"

    echo "Checking if RouteStack exists..." | tee -a $LOG_FILE
    if stack_exists "$ROUTE_STACK_NAME"; then
        echo "RouteStack exists. Updating..." | tee -a $LOG_FILE
        aws cloudformation update-stack \
            --stack-name "$ROUTE_STACK_NAME" \
            --template-url "https://s3.$REGION.amazonaws.com/$S3_BUCKET/route.yaml" \
            --parameters \
                ParameterKey=VPC1Id,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC1Id'].OutputValue" --output text) \
                ParameterKey=VPC2Id,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2Id'].OutputValue" --output text) \
                ParameterKey=VPC3Id,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC3Id'].OutputValue" --output text) \
                ParameterKey=VPC1PrivateSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC1PrivateSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC2PrivateSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2PrivateSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC2PublicSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2PublicSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC3PublicSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC3PublicSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC2InternetGatewayId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2InternetGatewayId'].OutputValue" --output text) \
                ParameterKey=VPC3InternetGatewayId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC3InternetGatewayId'].OutputValue" --output text) \
                ParameterKey=VPC2NatGatewayId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2NatGatewayId'].OutputValue" --output text) \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" 2>&1 | tee -a $LOG_FILE

        echo "Waiting for RouteStack update to complete..." | tee -a $LOG_FILE
        aws cloudformation wait stack-update-complete --stack-name "$ROUTE_STACK_NAME" --region "$REGION"

    else
        echo "RouteStack does not exist. Creating..." | tee -a $LOG_FILE
        aws cloudformation create-stack \
            --stack-name "$ROUTE_STACK_NAME" \
            --template-url "https://s3.$REGION.amazonaws.com/$S3_BUCKET/route.yaml" \
            --parameters \
                ParameterKey=VPC1Id,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC1Id'].OutputValue" --output text) \
                ParameterKey=VPC2Id,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2Id'].OutputValue" --output text) \
                ParameterKey=VPC3Id,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC3Id'].OutputValue" --output text) \
                ParameterKey=VPC1PrivateSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC1PrivateSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC2PrivateSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2PrivateSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC2PublicSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2PublicSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC3PublicSubnetId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC3PublicSubnetId'].OutputValue" --output text) \
                ParameterKey=VPC2InternetGatewayId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2InternetGatewayId'].OutputValue" --output text) \
                ParameterKey=VPC3InternetGatewayId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC3InternetGatewayId'].OutputValue" --output text) \
                ParameterKey=VPC2NatGatewayId,ParameterValue=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
                    --query "Stacks[0].Outputs[?OutputKey=='VPC2NatGatewayId'].OutputValue" --output text) \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" 2>&1 | tee -a $LOG_FILE

        echo "Waiting for RouteStack creation to complete..." | tee -a $LOG_FILE
        aws cloudformation wait stack-create-complete --stack-name "$ROUTE_STACK_NAME" --region "$REGION"
    fi
}

# Function to retrieve stack outputs
get_stack_outputs() {
    echo "Fetching stack outputs..." | tee -a $LOG_FILE
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
        --query "Stacks[0].Outputs" --output table | tee -a $LOG_FILE

    echo "Fetching RouteStack outputs..." | tee -a $LOG_FILE
    aws cloudformation describe-stacks --stack-name "$ROUTE_STACK_NAME" --region "$REGION" \
        --query "Stacks[0].Outputs" --output table | tee -a $LOG_FILE
}

# Execute the script
check_s3_bucket
upload_templates
deploy_stack
get_stack_outputs
