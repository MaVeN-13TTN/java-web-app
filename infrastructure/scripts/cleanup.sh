#!/bin/bash
# cleanup.sh - Full cleanup script for java-web-app CI/CD project
# Created: April 2, 2025
# Purpose: Destroy all AWS resources provisioned for the CI/CD pipeline

set -e

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting cleanup of AWS resources for java-web-app CI/CD project...${NC}\n"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install AWS CLI and try again.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed. Please install Terraform and try again.${NC}"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not configured. Please run 'aws configure' and try again.${NC}"
    exit 1
fi

# Project root directory - corrected path calculation
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(dirname "$(dirname "${SCRIPT_DIR}")")
TERRAFORM_DIR="${ROOT_DIR}/infrastructure/terraform"

# Change to Terraform directory
echo -e "${YELLOW}Changing to Terraform directory: $TERRAFORM_DIR${NC}"
cd "$TERRAFORM_DIR"

# Verify terraform initialization
if [ ! -d .terraform ]; then
    echo -e "${YELLOW}Terraform not initialized. Running terraform init...${NC}"
    terraform init
fi

# Check for terraform.tfstate
if [ ! -f terraform.tfstate ]; then
    echo -e "${YELLOW}Warning: terraform.tfstate not found. This may indicate that resources were never created or were created with a different state file.${NC}"
    read -p "Do you want to continue with the cleanup? (y/n): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        echo -e "${RED}Cleanup aborted.${NC}"
        exit 0
    fi
fi

# Backup terraform state file
echo -e "${YELLOW}Creating backup of terraform state...${NC}"
if [ -f terraform.tfstate ]; then
    cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)
fi

# Run Terraform destroy
echo -e "${YELLOW}Running terraform destroy...${NC}"
terraform destroy -auto-approve

echo -e "${GREEN}Terraform destroy completed.${NC}\n"

# Verify and clean up any remaining EC2 instances
echo -e "${YELLOW}Checking for any remaining EC2 instances...${NC}"
INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*-Server,*-Environment" --query "Reservations[*].Instances[*].[InstanceId,State.Name]" --output text | grep -v terminated || true)
if [ ! -z "$INSTANCES" ]; then
    echo -e "${YELLOW}Found the following instances:${NC}"
    echo "$INSTANCES"
    echo -e "${YELLOW}Terminating instances...${NC}"
    INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}')
    for ID in $INSTANCE_IDS; do
        echo "Terminating instance: $ID"
        aws ec2 terminate-instances --instance-ids "$ID"
    done
    echo -e "${YELLOW}Waiting for instances to terminate...${NC}"
    for ID in $INSTANCE_IDS; do
        aws ec2 wait instance-terminated --instance-ids "$ID"
        echo "Instance $ID terminated"
    done
else
    echo -e "${GREEN}No running instances found.${NC}"
fi

# Check for unattached EBS volumes
echo -e "${YELLOW}Checking for unattached EBS volumes...${NC}"
VOLUMES=$(aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[*].[VolumeId,Size]" --output text || true)
if [ ! -z "$VOLUMES" ]; then
    echo -e "${YELLOW}Found the following unattached volumes:${NC}"
    echo "$VOLUMES"
    VOLUME_IDS=$(echo "$VOLUMES" | awk '{print $1}')
    for VOLUME_ID in $VOLUME_IDS; do
        echo "Deleting volume: $VOLUME_ID"
        aws ec2 delete-volume --volume-id "$VOLUME_ID"
    done
else
    echo -e "${GREEN}No unattached volumes found.${NC}"
fi

# Check for project-related security groups
echo -e "${YELLOW}Checking for remaining security groups...${NC}"
SG_INFO=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default'].[GroupId,GroupName]" --output text || true)
if [ ! -z "$SG_INFO" ]; then
    echo -e "${YELLOW}Found the following security groups:${NC}"
    echo "$SG_INFO"
    echo -e "${YELLOW}Note: Security groups may not be deleted immediately if they have dependencies.${NC}"
    echo -e "${YELLOW}They will be removed automatically when the dependencies are resolved.${NC}"
fi

# Check for any elastic IPs
echo -e "${YELLOW}Checking for unassociated Elastic IPs...${NC}"
EIPS=$(aws ec2 describe-addresses --query "Addresses[?AssociationId==null].[AllocationId]" --output text || true)
if [ ! -z "$EIPS" ]; then
    echo -e "${YELLOW}Found the following unassociated Elastic IPs:${NC}"
    echo "$EIPS"
    for EIP in $EIPS; do
        echo "Releasing Elastic IP: $EIP"
        aws ec2 release-address --allocation-id "$EIP"
    done
else
    echo -e "${GREEN}No unassociated Elastic IPs found.${NC}"
fi

# Check for any load balancers
echo -e "${YELLOW}Checking for any load balancers...${NC}"
LBS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].[LoadBalancerArn,LoadBalancerName]" --output text 2>/dev/null || true)
if [ ! -z "$LBS" ]; then
    echo -e "${YELLOW}Found the following load balancers:${NC}"
    echo "$LBS"
    LB_ARNS=$(echo "$LBS" | awk '{print $1}')
    for LB_ARN in $LB_ARNS; do
        echo "Deleting load balancer: $LB_ARN"
        aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN"
    done
else
    echo -e "${GREEN}No load balancers found.${NC}"
fi

# Final verification
echo -e "\n${GREEN}Cleanup completed.${NC}"
echo -e "${YELLOW}Please verify in the AWS Console that all resources have been properly removed.${NC}"
echo -e "${YELLOW}Important resources to check:${NC}"
echo -e " - EC2 Instances: https://console.aws.amazon.com/ec2/v2/home?#Instances:"
echo -e " - Volumes: https://console.aws.amazon.com/ec2/v2/home?#Volumes:"
echo -e " - Security Groups: https://console.aws.amazon.com/ec2/v2/home?#SecurityGroups:"
echo -e " - VPCs: https://console.aws.amazon.com/vpc/home?#vpcs:"
echo -e " - Elastic IPs: https://console.aws.amazon.com/ec2/v2/home?#Addresses:"

echo -e "\n${GREEN}Thank you for using the cleanup script for the java-web-app CI/CD pipeline!${NC}"