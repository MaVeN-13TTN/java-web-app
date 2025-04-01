#!/bin/bash
# deploy.sh - Script to deploy the application to environments using Ansible

set -e  # Exit immediately if a command exits with a non-zero status

echo "===== Starting deployment process ====="

# Environment validation
if [ -z "$1" ]; then
    echo "ERROR: Environment parameter not provided!"
    echo "Usage: ./deploy.sh [dev|build|deploy]"
    exit 1
fi

ENV=$1
ANSIBLE_INVENTORY="../infrastructure/ansible/inventory.yml"
ANSIBLE_PLAYBOOK="../infrastructure/ansible/deploy.yml"

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "ERROR: Ansible is not installed!"
    echo "Please install Ansible: sudo yum install -y ansible"
    exit 1
fi

# Check if inventory file exists
if [ ! -f "$ANSIBLE_INVENTORY" ]; then
    echo "ERROR: Ansible inventory file not found at $ANSIBLE_INVENTORY"
    exit 1
fi

# Check if playbook file exists
if [ ! -f "$ANSIBLE_PLAYBOOK" ]; then
    echo "ERROR: Ansible playbook file not found at $ANSIBLE_PLAYBOOK"
    exit 1
fi

# Upload artifact to Nexus (if NEXUS_URL is provided)
if [ -n "$NEXUS_URL" ]; then
    echo "Uploading artifact to Nexus repository..."
    mvn deploy -DaltDeploymentRepository=nexus::default::${NEXUS_URL}
    echo "Artifact uploaded successfully!"
fi

# Run deployment with appropriate limit based on environment
echo "Deploying to $ENV environment..."
ansible-playbook -i $ANSIBLE_INVENTORY $ANSIBLE_PLAYBOOK --limit $ENV -e "nexus_host=$NEXUS_HOST"

# Check deployment status
if [ $? -eq 0 ]; then
    echo "===== Deployment to $ENV completed successfully ====="
else
    echo "===== Deployment to $ENV failed! ====="
    exit 1
fi