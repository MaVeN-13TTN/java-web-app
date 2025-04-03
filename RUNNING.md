# Java Web App CI/CD Pipeline - Setup and Running Guide

![CI/CD Pipeline](https://via.placeholder.com/800x200/0078D7/FFFFFF?text=Java+Web+App+CI/CD+Pipeline)

**Version:** 1.0.6  
**Last Updated:** April 2, 2025  
**Author:** DevOps Team

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Working Environments](#working-environments)
- [Project Setup](#project-setup)
  - [AWS Infrastructure Setup](#aws-infrastructure-setup)
  - [GitHub Repository Setup](#github-repository-setup)
  - [CI/CD Components Installation](#cicd-components-installation)
  - [Application Deployment](#application-deployment)
- [Running the Pipeline](#running-the-pipeline)
  - [Initial Pipeline Run](#initial-pipeline-run)
  - [Monitoring Pipeline Execution](#monitoring-pipeline-execution)
  - [Manual Approvals](#manual-approvals)
  - [Post-Configuration Communication Checks](#post-configuration-communication-checks)
- [Optional Server Identification](#optional-server-identification)
  - [Changing Server Hostnames](#changing-server-hostnames)
  - [Customizing Terminal Prompt](#customizing-terminal-prompt)
- [Detailed Components Configuration](#detailed-components-configuration)
  - [Jenkins Configuration](#jenkins-configuration)
  - [Robust Jenkins Plugin Installation](#robust-jenkins-plugin-installation)
  - [SonarQube Configuration](#sonarqube-configuration)
  - [Nexus Configuration](#nexus-configuration)
  - [Prometheus & Grafana Configuration](#prometheus--grafana-configuration)
- [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
  - [Infrastructure Issues](#infrastructure-issues)
  - [Jenkins Issues](#jenkins-issues)
  - [SonarQube Issues](#sonarqube-issues)
  - [Nexus Issues](#nexus-issues)
  - [GitHub Integration Issues](#github-integration-issues)
  - [Deployment Issues](#deployment-issues)
  - [Monitoring Issues](#monitoring-issues)
- [Maintenance](#maintenance)
  - [Backup Procedures](#backup-procedures)
  - [Updating Components](#updating-components)
  - [Security Maintenance](#security-maintenance)
- [Security and Credentials Management](#security-and-credentials-management)

---

## Introduction

This document provides comprehensive instructions for setting up and running the CI/CD pipeline for the Java Web Application. The pipeline automates the entire process from code commit to production deployment, utilizing various DevOps tools including Jenkins, SonarQube, Nexus, Trivy, Ansible, Prometheus, and Grafana.

![Pipeline Overview](https://via.placeholder.com/800x400/0078D7/FFFFFF?text=Pipeline+Architecture+Diagram)

---

## Prerequisites

Before proceeding with the setup, ensure you have the following prerequisites:

| Requirement                       | Description                                                                   | Version   |
| --------------------------------- | ----------------------------------------------------------------------------- | --------- |
| **AWS Account**                   | Account with permissions to create EC2 instances, VPCs, security groups, etc. | N/A       |
| **Local Development Environment** | Environment with required tools                                               | See below |
| **GitHub Account**                | Account with permissions to create repositories and webhooks                  | N/A       |
| **SSH Key Pair**                  | Named "DevOpsKey.pem" for EC2 instance access                                 | RSA 2048+ |
| **Domain Name**                   | Optional but recommended for production deployments                           | N/A       |

### Required Local Tools

- AWS CLI (configured with access credentials)
- Terraform (v1.0.0+)
- Ansible (v2.9+)
- Git
- SSH client

### Verifying Prerequisites

Run the following commands to verify your environment is properly set up:

```bash
# Check Terraform version
terraform -version
# Should return Terraform v1.0.0 or higher

# Check AWS CLI version
aws --version
# Should return aws-cli version

# Check Ansible version
ansible --version
# Should return ansible version 2.9.0 or higher

# Check Git version
git --version
# Should return git version

# Check SSH client
ssh -V
# Should return OpenSSH version

# Verify AWS credentials are configured
aws sts get-caller-identity
# Should return your AWS account ID, user ID, and ARN

# Get latest Amazon Linux 2023 AMI ID
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*" "Name=state,Values=available" --query "sort_by(Images, &CreationDate)[-1].[ImageId]" --output text --region us-east-1
# Should return an AMI ID (e.g., ami-05d9b53b86dec19c8) that you'll use in your Terraform configuration
```

### Setting Up AWS Credentials

If the `aws sts get-caller-identity` command returns an error about missing credentials, follow these steps to configure AWS:

1. **Create an IAM User in AWS Console**:

   - Log in to AWS Management Console
   - Navigate to IAM (Identity and Access Management)
   - Create a new user with programmatic access
   - Attach policies: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`, `AmazonS3FullAccess`
   - Save the Access Key ID and Secret Access Key

2. **Configure AWS CLI**:

   ```bash
   aws configure
   ```

   You will be prompted to enter:

   - AWS Access Key ID: [Enter your access key]
   - AWS Secret Access Key: [Enter your secret key]
   - Default region name: [Enter your preferred region, e.g., us-east-1]
   - Default output format: [Enter json]

3. **Verify Configuration**:

   ```bash
   aws sts get-caller-identity
   ```

   This should now return your AWS account details, confirming your credentials are set up correctly.

### Creating the DevOpsKey SSH Key Pair

The following steps will guide you through creating an SSH key pair for accessing your AWS EC2 instances:

1. **Generate SSH Key Pair**:

   ```bash
   # Create .ssh directory if it doesn't exist
   mkdir -p ~/.ssh

   # Generate a new RSA 4096-bit key
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/DevOpsKey

   # When prompted for passphrase, press Enter twice (no passphrase)
   # This is recommended for automation purposes
   ```

2. **Convert to PEM Format for AWS Compatibility**:

   ```bash
   # Convert the OpenSSH format key to PEM format
   ssh-keygen -p -m PEM -f ~/.ssh/DevOpsKey

   # When prompted for passphrase, press Enter (current passphrase)
   # When prompted for new passphrase, press Enter twice (no passphrase)

   # Create a copy with .pem extension for AWS
   cp ~/.ssh/DevOpsKey ~/.ssh/DevOpsKey.pem

   # Set proper permissions
   chmod 400 ~/.ssh/DevOpsKey.pem
   chmod 400 ~/.ssh/DevOpsKey
   ```

3. **Import Public Key to AWS**:

   ```bash
   # Import the public key to AWS
   aws ec2 import-key-pair --key-name "DevOpsKey" --public-key-material fileb://~/.ssh/DevOpsKey.pub
   ```

4. **Verify Key Pair Import**:
   ```bash
   # List your key pairs to verify
   aws ec2 describe-key-pairs --key-name "DevOpsKey"
   ```

> **Note**: Modern OpenSSH keys (since OpenSSH 7.8) use a format that OpenSSL cannot directly read. The above steps ensure compatibility with both OpenSSH and AWS EC2, which requires keys in PEM format.

### Testing SSH Configuration

Ensure your SSH config recognizes the key:

```bash
# Add key to SSH agent (optional)
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/DevOpsKey.pem

# Test SSH connection (once EC2 instances are created)
# Replace <EC2-IP> with your instance's public IP
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<EC2-IP>
```

After completing these steps, you will have properly configured AWS credentials and created the required SSH key for EC2 access.

---

## Infrastructure Specifications

The CI/CD pipeline is built using the following AWS infrastructure configuration:

| Component         | Value                 | Notes                                |
| ----------------- | --------------------- | ------------------------------------ |
| AWS Region        | us-east-1             | US East (N. Virginia)                |
| Project Name      | java-cicd             | Used as a prefix for resource naming |
| VPC CIDR          | 10.0.0.0/16           | Virtual Private Cloud network range  |
| Subnet CIDR       | 10.0.1.0/24           | Subnet for all infrastructure        |
| Availability Zone | us-east-1a            | Single AZ deployment                 |
| AMI               | ami-0c02fb55956c7d316 | Amazon Linux 2                       |
| SSH Key Name      | DevOpsKey             | Key pair for EC2 access              |

### EC2 Instance Specifications

The pipeline uses the following EC2 instance types:

| Server            | Instance Type | Purpose                   |
| ----------------- | ------------- | ------------------------- |
| Jenkins Server    | t2.medium     | CI/CD orchestration       |
| SonarQube Server  | t2.medium     | Code quality analysis     |
| Nexus Server      | t2.medium     | Artifact repository       |
| Dev Server        | t2.micro      | Development environment   |
| Build Server      | t2.micro      | Build/testing environment |
| Deploy Server     | t2.micro      | Production environment    |
| Prometheus Server | t2.micro      | Metrics collection        |
| Grafana Server    | t2.micro      | Metrics visualization     |

> **Note**: These specifications are defined in `infrastructure/terraform/terraform.tfvars` and can be modified before deployment to suit your resource requirements.

---

## Working Environments

This CI/CD pipeline involves working with multiple environments. For clarity, here's where you'll be performing different tasks:

### 🖥️ Local Development Machine

**Activities performed on your local workstation**:

- Initial repository cloning and code development
- Terraform configuration and infrastructure provisioning
- Running Ansible playbooks to configure servers
- Git operations (commit, push, etc.)
- SSH connections to EC2 instances for maintenance

**Commands run locally** will be shown like this:

```bash
# This is run on your local machine
terraform apply
```

### ☁️ AWS EC2 Instances

**Provisioned AWS infrastructure components**:

The following AWS EC2 instances will be provisioned, each serving a specific purpose:

| Server            | Purpose                   | Default Size |
| ----------------- | ------------------------- | ------------ |
| Jenkins Server    | CI/CD orchestration       | t2.medium    |
| SonarQube Server  | Code quality analysis     | t2.medium    |
| Nexus Server      | Artifact repository       | t2.medium    |
| Dev Server        | Development environment   | t2.micro     |
| Build Server      | Build/testing environment | t2.micro     |
| Deploy Server     | Production environment    | t2.micro     |
| Prometheus Server | Metrics collection        | t2.micro     |
| Grafana Server    | Metrics visualization     | t2.micro     |

**Commands run on EC2 instances** will be shown like this:

```bash
# This is run on the Jenkins EC2 instance
sudo systemctl restart jenkins
```

### 🌐 Web Interfaces

**Web-based management interfaces**:

| Component     | URL                             | Purpose                               |
| ------------- | ------------------------------- | ------------------------------------- |
| Jenkins UI    | http://<Jenkins-EC2-IP>:8080    | Pipeline configuration and monitoring |
| SonarQube UI  | http://<SonarQube-EC2-IP>:9000  | Code quality analysis results         |
| Nexus UI      | http://<Nexus-EC2-IP>:8081      | Artifact repository management        |
| Prometheus UI | http://<Prometheus-EC2-IP>:9090 | Metrics query and monitoring          |
| Grafana UI    | http://<Grafana-EC2-IP>:3000    | Dashboard visualization               |
| GitHub UI     | https://github.com/             | Repository configuration              |

> **Note**: Throughout this guide, tasks are organized to clearly indicate which environment they should be performed in.

---

## Project Setup

### AWS Infrastructure Setup

#### 1. Clone the Repository (Local Machine)

```bash
git clone https://github.com/YOUR-USERNAME/java-web-app.git
cd java-web-app
```

#### 2. Customize Infrastructure Configuration

Review and modify the Terraform variables in `infrastructure/terraform/terraform.tfvars` to suit your requirements:

```bash
cd infrastructure/terraform
# Edit terraform.tfvars file to customize instance types, region, AMI, etc.
vim terraform.tfvars
```

**Key configurations to review**:

- `aws_region`: Currently set to "us-east-1" (US East - N. Virginia)
- `instance_types`: EC2 instance sizes (t2.medium for Jenkins, SonarQube, Nexus; t2.micro for others)
- `key_name`: Must match "DevOpsKey" or your custom AWS key pair name
- `vpc_cidr` and `subnet_cidr`: Network configuration (10.0.0.0/16 and 10.0.1.0/24)
- `aws_ami`: Update with the latest Amazon Linux 2023 AMI ID

**Updating Terraform variables with latest Amazon Linux 2023 AMI ID**:

1. After retrieving the latest AMI ID using the AWS CLI command mentioned in the prerequisites section, update your Terraform variables file:

```bash
# Get the latest Amazon Linux 2023 AMI ID
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*" "Name=state,Values=available" --query "sort_by(Images, &CreationDate)[-1].[ImageId]" --output text --region us-east-1)

# Display the AMI ID
echo "Latest Amazon Linux 2023 AMI ID: $AMI_ID"

# Update the terraform.tfvars file with the new AMI ID
# For Linux/MacOS
sed -i "s/aws_ami = \".*\"/aws_ami = \"$AMI_ID\"/" terraform.tfvars

# Alternatively, you can manually edit the terraform.tfvars file and replace the aws_ami value
```

2. Verify the update was successful:

```bash
grep "aws_ami" terraform.tfvars
```

This ensures your infrastructure uses the most up-to-date Amazon Linux 2023 AMI which includes the latest security patches and performance improvements.

**Cost considerations**:

- The default configuration uses t2.medium instances for Jenkins, SonarQube, and Nexus, which may incur significant AWS costs
- For development or testing purposes, you can downgrade to t2.small or t2.micro instances
- Adjust the instance types based on your performance needs and budget constraints

#### 3. Deploy the Infrastructure

Initialize Terraform and apply the configuration:

```bash
terraform init
terraform plan -out=tfplan  # Review the plan and provide a filename[tfplan] where the plan will be saved
terraform apply "tfplan" # Type 'yes' when prompted
```

This process will take approximately 5-10 minutes and will provision:

- 8 EC2 instances (Jenkins, SonarQube, Nexus, Dev, Build, Deploy, Prometheus, Grafana)
- Networking components (VPC, subnet, internet gateway, route tables)
- Security groups

#### 4. Update Configuration Files with IP Addresses

After the infrastructure is deployed, use the provided script to automatically update all configuration files with the EC2 IP addresses:

```bash
cd /path/to/java-web-app
chmod +x infrastructure/scripts/update_ip_addresses.sh
./infrastructure/scripts/update_ip_addresses.sh
```

**What this script does**:

- Retrieves all EC2 IP addresses from Terraform outputs
- Updates Ansible inventory, Jenkinsfile, GitHub workflow, and Prometheus configuration
- Creates backups of all modified files
- Generates a summary report with server information and service URLs

Verify the script execution by checking the generated summary file:

```bash
cat ip_address_update_summary.txt
```

### GitHub Repository Setup

#### 1. Create a GitHub Repository

- Create a new repository on GitHub for your Java web application
- Initialize with a README and .gitignore for Java
- Push your local code to the GitHub repository:

```bash
git remote set-url origin https://github.com/YOUR-USERNAME/java-web-app.git
git push -u origin main
```

#### 2. Set Up Branch Protection

- Navigate to Settings > Branches in your GitHub repository
- Add a rule to protect the main branch:
  - Require pull request reviews before merging
  - Require status checks to pass before merging
  - Require branches to be up to date before merging

#### 3. Generate GitHub Access Token

- Go to GitHub Settings > Developer settings > Personal access tokens
- Generate a token with `repo`, `admin:repo_hook`, and `workflow` scopes
- Save this token securely for Jenkins configuration

#### 4. Configure GitHub Webhook

**Detailed GitHub Webhook Configuration**:

1. **Access Repository Settings**

   - Log in to GitHub and navigate to your repository
   - Click on the Settings tab in the repository navigation bar (requires admin access)
   - In the left sidebar, select Webhooks
   - Click the Add webhook button in the upper right

2. **Configure the Webhook Payload**

   - Payload URL: `http://<Jenkins-IP>:8080/github-webhook/` (replace `<Jenkins-IP>` with your actual Jenkins server's public IP)
   - Content Type: Select `application/json` from the dropdown menu
   - Secret (Optional but Recommended): Create a secure, random string as your webhook secret
   - SSL Verification: For production environments, properly configured SSL is recommended

3. **Select Webhook Events**

   - Select "Let me select individual events"
   - Check the following events:
     - Push - Triggers builds when code is pushed to any branch
     - Pull requests - Triggers builds when PRs are opened, updated, or synchronized
     - Pull request reviews - Triggers builds when reviewers approve or request changes

4. **Active Status**

   - Ensure the Active checkbox is selected to enable the webhook

5. **Verify Configuration**
   - After creating the webhook, GitHub will send a ping event to your Jenkins server
   - Verify the ping was successful by checking for a green checkmark

### CI/CD Components Installation

#### 1. Configure Ansible and SSH

Ensure your SSH key is properly configured:

```bash
# Copy your private key to the .ssh directory
cp /path/to/DevOpsKey.pem ~/.ssh/
chmod 400 ~/.ssh/DevOpsKey.pem
```

Verify connectivity to your EC2 instances:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP>
```

#### 2. Set Up GitHub Credentials for Ansible

Before deploying Jenkins, you need to set up the GitHub credentials that will be used for integration:

```bash
# Navigate to Ansible directory
cd infrastructure/ansible

# Create vars directory if it doesn't exist
mkdir -p vars

# Create GitHub credentials file
cat > vars/github_credentials.yml << 'EOF'
---
# GitHub Credentials - Replace with your actual credentials
# GitHub username for API access
github_username: "your-github-username"

# GitHub personal access token with appropriate permissions
# Required scopes: repo, admin:repo_hook, workflow
github_token: "your-github-personal-access-token"
EOF

# Set appropriate permissions
chmod 600 vars/github_credentials.yml
```

##### How to Use the Credentials File

To use this setup securely:

1. **Encrypt the credentials file**:

   ```bash
   ansible-vault encrypt vars/github_credentials.yml
   ```

   You'll be prompted to create a password for the vault.

2. **Run the playbook with the vault password**:
   ```bash
   ansible-playbook -i inventory.yml jenkins-setup.yml --ask-vault-pass
   ```
   You'll be prompted for the vault password during execution.

This approach ensures your GitHub credentials are:

- Securely stored (encrypted with Ansible Vault)
- Never committed to version control
- Available to your playbook when needed
- Used securely in Jenkins (via environment variables)

The Jenkins playbook will now properly fetch and use your GitHub credentials when setting up GitHub integration.

#### 3. Deploy Jenkins

```bash
cd infrastructure/ansible
ansible-playbook -i inventory.yml jenkins-setup.yml --ask-vault-pass
```

**Post-deployment steps**:

After deployment is complete:

- Access Jenkins at http://<Jenkins-EC2-IP>:8080
- Retrieve the initial admin password:
  ```bash
  ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP> "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  ```
- Complete the Jenkins setup wizard:
  - Install suggested plugins
  - Create an admin user
  - Configure Jenkins URL

#### 4. Deploy SonarQube

```bash
ansible-playbook -i inventory.yml sonarqube-setup.yml
```

**Post-deployment steps**:

After deployment is complete:

- Access SonarQube at http://<SonarQube-EC2-IP>:9000
- Log in with default credentials (admin/admin)
- Change the default password
- Configure a new project:
  - Create a new project manually
  - Set up the project key as "java-web-app"
  - Generate a token for Jenkins integration

#### 5. Deploy Nexus and Trivy

```bash
ansible-playbook -i inventory.yml nexus-setup.yml
```

**Post-deployment steps**:

After deployment is complete:

- Access Nexus at http://<Nexus-EC2-IP>:8081
- Retrieve the initial admin password:
  ```bash
  ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Nexus-EC2-IP> "sudo cat /opt/sonatype-work/nexus3/admin.password"
  ```
- Complete the Nexus setup wizard:
  - Change the default password (admin/admin123)
  - Create Maven repositories:
    - maven-releases
    - maven-snapshots
    - maven-proxy (proxy for Maven Central)

#### 6. Deploy Monitoring Tools

```bash
ansible-playbook -i inventory.yml monitoring-setup.yml
```

**Post-deployment steps**:

After deployment is complete:

- Access Prometheus at http://<Prometheus-EC2-IP>:9090
- Access Grafana at http://<Grafana-EC2-IP>:3000
- Log in to Grafana with default credentials (admin/admin)
- Configure Prometheus as a data source in Grafana:
  - Name: Prometheus
  - Type: Prometheus
  - URL: http://<Prometheus-EC2-IP>:9090
  - Access: Server (default)
- Import the provided dashboard from `monitoring/grafana/dashboards/java-app-dashboard.json`

### Application Deployment

#### 1. Configure Jenkins Pipeline

**Jenkins configuration steps**:

In Jenkins:

1. Create a new Pipeline job:

   - Name: java-web-app
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: https://github.com/YOUR-USERNAME/java-web-app.git
   - Credentials: Add > Jenkins > Username with password > GitHub credentials
   - Branch Specifier: \*/main
   - Script Path: pipeline/Jenkinsfile

2. Configure Jenkins Credentials:

   - Navigate to Manage Jenkins > Manage Credentials
   - Add credentials for:
     - GitHub (Username with password)
     - SonarQube (Secret text, ID: sonar-token)
     - Nexus (Username with password)

3. Configure Jenkins System Settings:
   - Navigate to Manage Jenkins > Configure System
   - Find GitHub section and add GitHub Server
   - Test connection to verify GitHub integration

---

## Running the Pipeline

### Initial Pipeline Run

To initiate the pipeline for the first time:

**Manual Trigger**:

- Navigate to the java-web-app pipeline in Jenkins
- Click "Build Now" to start the pipeline

**Git Push Trigger**:

- Make a change to your codebase:
  ```bash
  cd /path/to/java-web-app
  # Make some changes to files
  git add .
  git commit -m "Initial pipeline run"
  git push origin main
  ```
- The webhook should automatically trigger the Jenkins pipeline

### Monitoring Pipeline Execution

**Monitoring options**:

1. **Jenkins Dashboard**:

   - Monitor the pipeline progress through the Jenkins UI
   - View stage execution details
   - Review console output for any errors

2. **SonarQube Analysis**:

   - Access SonarQube to review code quality analysis results
   - Check for code smells, bugs, vulnerabilities, and code coverage

3. **GitHub Status Checks**:
   - The pipeline will update status checks on GitHub for the commit/PR
   - Green checks indicate successful stages

### Manual Approvals

The pipeline includes manual approval gates before promoting to higher environments:

**Approval process**:

1. **Deploy to Build Environment**:

   - After successful deployment to Dev, the pipeline will pause
   - Review the application in the Dev environment: http://<Dev-EC2-IP>:8080/java-web-app
   - In Jenkins, click "Proceed" to continue with deployment to Build

2. **Deploy to Production**:
   - After successful deployment to Build, the pipeline will pause again
   - Review the application in the Build environment: http://<Build-EC2-IP>:8080/java-web-app
   - In Jenkins, click "Proceed" to continue with deployment to Production

### Post-Configuration Communication Checks

After setting up all components of the CI/CD pipeline, it's crucial to verify that all servers can communicate properly with each other. Follow these steps to ensure your infrastructure components are correctly connected.

#### Verifying Security Group Configuration

```bash
# Check security group rules after Terraform deployment
aws ec2 describe-security-groups --filters "Name=group-name,Values=java-cicd*"
```

Ensure these essential ports are open between servers:

- Jenkins → GitHub: Outbound 443
- GitHub → Jenkins: Inbound 8080
- Jenkins → SonarQube: 9000
- Jenkins → Nexus: 8081
- Jenkins → App Servers: 22 (SSH)
- Prometheus → All servers: Various metric ports (8080, 9090, 9100, etc.)
- Admin access → All servers: 22 (SSH)

#### Testing Inter-Service Communication

##### 1. Jenkins Connectivity Tests

```bash
# SSH to Jenkins server
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP>

# Test connectivity to GitHub
curl -I https://api.github.com

# Test connectivity to SonarQube
curl -I http://<SonarQube-EC2-IP>:9000

# Test connectivity to Nexus
curl -I http://<Nexus-EC2-IP>:8081

# Test SSH connectivity to application servers
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Dev-EC2-IP> exit
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Build-EC2-IP> exit
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Deploy-EC2-IP> exit
```

##### 2. SonarQube Configuration Test

```bash
# SSH to SonarQube server
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<SonarQube-EC2-IP>

# Test database connectivity
sudo -u sonar psql -h localhost -U sonar -d sonar -c "SELECT 1"

# Test webhook configuration to Jenkins
curl -I http://<Jenkins-EC2-IP>:8080
```

##### 3. Nexus Repository Tests

```bash
# SSH to Nexus server
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Nexus-EC2-IP>

# Test API connectivity
curl -u admin:your-nexus-password http://localhost:8081/service/rest/v1/repositories

# Test connectivity to application servers
curl -I http://<Dev-EC2-IP>:8080
curl -I http://<Build-EC2-IP>:8080
curl -I http://<Deploy-EC2-IP>:8080
```

##### 4. Prometheus Metrics Collection Test

```bash
# SSH to Prometheus server
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Prometheus-EC2-IP>

# Check if targets are being scraped successfully
curl http://localhost:9090/api/v1/targets | grep "state"

# Test connectivity to all monitored services
curl -I http://<Jenkins-EC2-IP>:8080/metrics
curl -I http://<SonarQube-EC2-IP>:9000/metrics
curl -I http://<Nexus-EC2-IP>:8081/metrics
curl -I http://<Dev-EC2-IP>:8080/metrics
curl -I http://<Build-EC2-IP>:8080/metrics
curl -I http://<Deploy-EC2-IP>:8080/metrics
```

##### 5. Application Server Tests

For each application server (Dev, Build, Deploy):

```bash
# SSH to application server
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<App-Server-IP>

# Verify Tomcat is running
sudo systemctl status tomcat

# Test connectivity to Nexus (for artifact retrieval)
curl -I http://<Nexus-EC2-IP>:8081
```

#### Validating CI/CD Pipeline Communication

To verify the entire pipeline's communication flow:

1. **Trigger a Test Pipeline Run**:

```bash
# Clone your repository (if not already done)
git clone https://github.com/YOUR-USERNAME/java-web-app.git
cd java-web-app

# Make a small change
echo "# CI/CD Test $(date)" >> README.md
git add README.md
git commit -m "Test CI/CD pipeline communication"
git push origin main
```

2. **Verify Communication Flow**:

- Check Jenkins console output for:
  - Successful GitHub webhook reception
  - Maven build execution
  - SonarQube analysis connection
  - Artifact upload to Nexus
  - Deployment to environments

3. **Verify Metric Collection**:

```bash
# Check Prometheus targets
curl -s http://<Prometheus-EC2-IP>:9090/api/v1/targets | grep "state\":\"up"

# Login to Grafana dashboard to verify data is flowing
# Navigate to http://<Grafana-EC2-IP>:3000 in your browser
```

#### Troubleshooting Common Communication Issues

| Issue                                | Diagnosis Command                                                                   | Solution                                                              |
| ------------------------------------ | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Jenkins can't reach GitHub           | `curl -v https://api.github.com`                                                    | Check outbound security group rules                                   |
| GitHub webhooks not reaching Jenkins | `sudo tail -f /var/log/jenkins/jenkins.log`                                         | Verify inbound security group rules and Jenkins webhook configuration |
| SonarQube not accessible             | `telnet <SonarQube-EC2-IP> 9000`                                                    | Check SonarQube service status and security group rules               |
| Nexus artifact upload fails          | `curl -v -u admin:password http://<Nexus-EC2-IP>:8081/service/rest/v1/repositories` | Verify Nexus service and credentials                                  |
| Application server unreachable       | `ping <App-Server-IP>` followed by `telnet <App-Server-IP> 8080`                    | Check security groups and service status                              |
| Prometheus cannot scrape metrics     | `curl http://<Target-IP>:<Port>/metrics`                                            | Verify target exporter is running and accessible                      |

#### Communication Flow Diagram

For reference, here's the expected communication flow between services:

```
GitHub <--> Jenkins <--> SonarQube
                ↓
                ↓
              Nexus
                ↓
                ↓
  Dev Server <- → Build Server <- → Production Server
                ↑        ↑        ↑
                ↑        ↑        ↑
            Prometheus <--> Grafana
```

This verification process ensures that all components of your CI/CD pipeline can communicate properly, preventing potential issues during operation.

---

## Optional Server Identification

### Changing Server Hostnames

For easier identification of each server when connected via SSH, you can change the hostname of each EC2 instance. This is especially helpful when managing multiple terminal connections to different servers.

Follow these steps for each server:

```bash
# SSH into the EC2 instance
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Server-EC2-IP>

# Switch to root user
sudo su -

# Install nano if not already available
yum install -y nano

# Edit the hostname file
nano /etc/hostname

# Replace the existing hostname with a descriptive name based on server role:
# For Jenkins server: jenkins-server
# For SonarQube server: sonarqube-server
# For Nexus server: nexus-server
# For Dev environment: dev-server
# For Build environment: build-server
# For Production environment: prod-server
# For Prometheus server: prometheus-server
# For Grafana server: grafana-server

# Save the file (press Ctrl+X, then press Y when prompted to save, then press Enter to confirm the filename)

# Apply the hostname change immediately
hostname -F /etc/hostname

# Edit the hosts file to include the new hostname
nano /etc/hosts

# Add your new hostname at the end of the localhost line
# Original:
# 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
# Modified (example for Jenkins server):
# 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 jenkins-server

# Leave the IPv6 localhost line unchanged:
# ::1         localhost6 localhost6.localdomain6

# Save the file and exit

# Verify the hostname change
hostname

# Exit root shell
exit

# Exit the SSH session
exit
```

After changing the hostnames, the next time you connect via SSH, your terminal prompt will show the server name, making it easier to identify which server you're working with.

> **Note**: You may need to restart the instance for all services to recognize the new hostname, though most will pick up the change immediately.

### Customizing Terminal Prompt

For even better visual differentiation, you can customize the bash prompt to include colors based on the server type. Add this to each server's root `.bashrc` file:

```bash
# SSH into the server
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Server-EC2-IP>

# Switch to root user
sudo su -

# Edit the .bashrc file
nano ~/.bashrc

# Add color-coded prompt based on server role
# For Jenkins: Blue prompt
echo 'export PS1="\[\033[0;34m\][\u@\h \W]\\$ \[\033[0m\]"' >> ~/.bashrc

# For SonarQube: Green prompt
# echo 'export PS1="\[\033[0;32m\][\u@\h \W]\\$ \[\033[0m\]"' >> ~/.bashrc

# For Nexus: Purple prompt
# echo 'export PS1="\[\033[0;35m\][\u@\h \W]\\$ \[\033[0m\]"' >> ~/.bashrc

# For application servers: different shades of yellow/orange
# echo 'export PS1="\[\033[0;33m\][\u@\h \W]\\$ \[\033[0m\]"' >> ~/.bashrc

# Save the file and exit

# Apply changes
source ~/.bashrc
```

Uncomment the appropriate line for each server type. This creates a color-coded terminal experience where each server type has a distinct colored prompt, making it immediately obvious which server you're connected to.

This is especially useful during troubleshooting when you might have multiple terminal windows open simultaneously.

---

## Detailed Components Configuration

### Jenkins Configuration

**Additional Plugins Installation**:

In addition to the plugins installed by Ansible, you may want to install:

1. **Blue Ocean**: For improved pipeline visualization

   - Manage Jenkins > Plugin Manager > Available > Search for "Blue Ocean" > Install

2. **Email Extension Plugin**: For enhanced email notifications
   - Manage Jenkins > Plugin Manager > Available > Search for "Email Extension" > Install

**GitHub Integration Fine-Tuning**:

To improve GitHub integration:

1. **Configure GitHub Server**:

   - Manage Jenkins > Configure System
   - GitHub section > Add GitHub Server
   - Name: GitHub
   - API URL: https://api.github.com
   - Credentials: Select your GitHub credentials
   - Test connection to verify

2. **Configure GitHub Webhook**:
   - If using a secret in your GitHub webhook configuration:
     - Update Jenkins configuration with the same secret
     - Manage Jenkins > Configure System > GitHub > Advanced > Secret text

**Pipeline Library Setup**:

For shared pipeline functions:

1. **Configure Global Pipeline Library**:
   - Manage Jenkins > Configure System
   - Global Pipeline Libraries > Add
   - Name: pipeline-library
   - Default version: main
   - Source Code Management: Git
   - Project Repository: URL to your pipeline library repository
   - Credentials: GitHub credentials
   - Save configuration

---

### Robust Jenkins Plugin Installation

### Improved Plugin Installation Process

The standard Jenkins plugin installation process can sometimes fail when installing multiple plugins at once. Our ansible playbook includes an improved method for reliable plugin installation:

```bash
# This approach is implemented in jenkins-setup.yml
- name: Install Jenkins plugins individually
  command: >
    java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/ -auth admin:{{ jenkins_admin_password.stdout }}
    install-plugin {{ item }} -deploy
  loop: "{{ jenkins_plugins }}"
  register: plugin_result
  failed_when: plugin_result.rc != 0 and 'already installed' not in plugin_result.stderr|default('')
  changed_when: "'Installing' in plugin_result.stdout|default('')"
  retries: 3
  delay: 10
  until: plugin_result is success or ('already installed' in plugin_result.stderr|default(''))
  notify: Restart Jenkins
```

Key improvements in this approach:

1. **Individual Installation**: Each plugin is installed separately, allowing the process to continue even if one plugin fails
2. **Retry Logic**: Each plugin installation attempts up to 3 times with 10-second delays between attempts
3. **Better Error Handling**: The task doesn't fail if a plugin is already installed
4. **Proper Status Tracking**: Changes are properly tracked based on installation output

If you need to install additional plugins manually after initial setup, you can use the Jenkins UI or run this command:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP>
sudo java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth admin:your-password install-plugin plugin-name -deploy
```

---

### SonarQube Configuration

**Quality Gates Configuration**:

Define custom quality gates for your project:

1. Navigate to Quality Gates > Create
2. Add conditions:
   - Coverage on New Code is less than 80%
   - Duplicated Lines on New Code is greater than 3%
   - Maintainability Rating is worse than A
   - Reliability Rating is worse than A
   - Security Rating is worse than A
   - Security Hotspots Reviewed is less than 100%

**GitHub Integration**:

Enable SonarQube to provide feedback on pull requests:

1. Navigate to Administration > Configuration > GitHub
2. Enter your GitHub token
3. Configure pull request decoration settings

### Nexus Configuration

**Repository Cleanup Policies**:

To manage disk usage:

1. Navigate to Administration > Repository > Cleanup Policies
2. Create a new policy:
   - Name: snapshot-cleanup
   - Format: maven2
   - Criteria: Last downloaded before 60 days ago
3. Apply this policy to your maven-snapshots repository

**Nexus Repository Manager API**:

For programmatic access to Nexus:

1. Create a Nexus user with appropriate roles
2. Use the Nexus REST API for tasks like:
   - Repository creation
   - Artifact upload/download
   - User management

Example API call to list repositories:

```bash
curl -u admin:password http://<Nexus-EC2-IP>:8081/service/rest/v1/repositories
```

### Prometheus & Grafana Configuration

**Advanced Prometheus Configuration**:

Edit `monitoring/prometheus/prometheus.yml` to add more targets and scrape configurations:

```yaml
scrape_configs:
  # Existing configs for Jenkins, SonarQube, Nexus

  # Add Node Exporter for server metrics
  - job_name: "node"
    static_configs:
      - targets:
          [
            "<Jenkins-EC2-IP>:9100",
            "<SonarQube-EC2-IP>:9100",
            "<Nexus-EC2-IP>:9100",
          ]

  # Add JMX Exporter for Java application metrics
  - job_name: "java-app"
    static_configs:
      - targets:
          ["<Dev-EC2-IP>:8080", "<Build-EC2-IP>:8080", "<Deploy-EC2-IP>:8080"]
    metrics_path: "/metrics"
```

**Additional Grafana Dashboards**:

Import additional dashboards to monitor different aspects of your infrastructure:

1. **Jenkins Performance Dashboard** (ID: 9964)
2. **Node Exporter Dashboard** (ID: 1860)
3. **JVM Dashboard** (ID: 4701)

To import a dashboard:

- Grafana UI > Create > Import > Enter dashboard ID

---

## Common Issues and Troubleshooting

### Infrastructure Issues

**AWS Resource Limits**:

**Problem**: Terraform fails to create resources due to AWS limits.

**Solution**:

1. Check your AWS service quotas in the AWS Management Console
2. Request limit increases if needed
3. Use smaller instance types or reduce the number of instances

**Security Group Connectivity**:

**Problem**: Services cannot communicate with each other.

**Solution**:

1. Verify security group rules allow traffic between your services
2. Use the following command to test connectivity:
   ```bash
   nc -zv <Target-IP> <Port>
   ```
3. Add missing security group rules using AWS console or Terraform

### Jenkins Issues

**Pipeline Fails to Start**:

**Problem**: Jenkins pipeline doesn't start automatically when code is pushed.

**Solution**:

1. Verify webhook configuration in GitHub:
   - Check payload URL is correct
   - Ensure content type is application/json
   - Confirm webhook is active
2. Check Jenkins webhook receiver:
   - Review Jenkins logs: `sudo tail -f /var/log/jenkins/jenkins.log`
   - Ensure Jenkins URL is correctly set in Configure System
3. Check network connectivity:
   - Confirm Jenkins server is accessible from the internet
   - Verify security group allows traffic on port 8080

**Plugin Compatibility Issues**:

**Problem**: Jenkins plugins conflict or don't work properly.

**Solution**:

1. Update all plugins: Manage Jenkins > Manage Plugins > Updates
2. Check plugin compatibility matrix in Jenkins wiki
3. If problems persist, downgrade problematic plugins to earlier versions

### SonarQube Issues

**Database Connection Issues**:

**Problem**: SonarQube cannot connect to its database.

**Solution**:

1. Verify PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```
2. Check database configuration in `/opt/sonarqube/conf/sonar.properties`
3. Ensure database credentials are correct
4. Restart SonarQube:
   ```bash
   sudo su - sonar -c "/opt/sonarqube/bin/linux-x86-64/sonar.sh restart"
   ```

**Out of Memory Errors**:

**Problem**: SonarQube crashes with out of memory errors.

**Solution**:

1. Increase memory allocation in `/opt/sonarqube/conf/sonar.properties`:
   ```
   sonar.web.javaOpts=-Xmx1G -Xms512m
   ```
2. Ensure your instance has enough RAM
3. Optimize analysis scope by excluding unnecessary files

### Nexus Issues

**Repository Access Problems**:

**Problem**: Cannot upload artifacts to Nexus.

**Solution**:

1. Verify Maven `settings.xml` configuration:
   ```xml
   <server>
     <id>nexus</id>
     <username>admin</username>
     <password>your-password</password>
   </server>
   ```
2. Check repository permissions in Nexus UI
3. Ensure Jenkins has the correct credentials for Nexus

**Disk Space Issues**:

**Problem**: Nexus runs out of disk space.

**Solution**:

1. Implement cleanup policies for old artifacts
2. Increase EBS volume size:

   ```bash
   # Identify volume
   aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId'

   # Modify volume
   aws ec2 modify-volume --volume-id <volume-id> --size 50
   ```

3. After resizing, extend the filesystem:
   ```bash
   sudo growpart /dev/xvda 1
   sudo xfs_growfs -d /
   ```

### GitHub Integration Issues

**Authentication Failures**:

**Problem**: Jenkins cannot authenticate with GitHub.

**Solution**:

1. Verify GitHub credentials in Jenkins:
   - Manage Jenkins > Manage Credentials
   - Check the GitHub username and token/password
2. Ensure token has the correct permissions:
   - repo
   - admin:repo_hook
   - workflow
3. Regenerate token if needed

**Webhook Delivery Failures**:

**Problem**: GitHub webhook calls fail to reach Jenkins.

**Solution**:

1. Verify webhook configuration:
   - GitHub Repository > Settings > Webhooks
   - Check "Recent Deliveries" for detailed error messages
2. Ensure Jenkins is accessible:
   - Confirm port 8080 is open in your security group
   - Check your EC2 instance's public IP hasn't changed
3. If using HTTPS, verify certificate validity

### Deployment Issues

**Tomcat Deployment Failures**:

**Problem**: Application WAR fails to deploy to Tomcat.

**Solution**:

1. Check Tomcat logs:
   ```bash
   sudo tail -f /opt/tomcat/logs/catalina.out
   ```
2. Verify WAR file was correctly downloaded from Nexus
3. Ensure Tomcat has proper permissions:
   ```bash
   sudo chown -R tomcat:tomcat /opt/tomcat/webapps
   ```
4. Restart Tomcat:
   ```bash
   sudo systemctl restart tomcat
   ```

**Ansible SSH Issues**:

**Problem**: Ansible fails to connect to target servers.

**Solution**:

1. Verify SSH key is properly configured:
   ```bash
   chmod 400 ~/.ssh/DevOpsKey.pem
   ```
2. Check inventory file for correct hostnames/IPs
3. Test SSH connection manually:
   ```bash
   ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Target-IP>
   ```
4. Add verbose output to Ansible for debugging:
   ```bash
   ansible-playbook -vvv -i inventory.yml playbook.yml
   ```

### Monitoring Issues

**Prometheus Target Down**:

**Problem**: Prometheus shows targets as down.

**Solution**:

1. Check if the target service is running
2. Verify network connectivity:
   ```bash
   curl http://<Target-IP>:<Port>/metrics
   ```
3. Check Prometheus configuration for correct endpoints
4. Ensure security groups allow traffic on the metrics port
5. Restart Prometheus:
   ```bash
   sudo systemctl restart prometheus
   ```

**Grafana Dashboard Not Showing Data**:

**Problem**: Grafana dashboards show "No data" error.

**Solution**:

1. Verify Prometheus data source is correctly configured:
   - Grafana UI > Configuration > Data Sources
   - Test connection to Prometheus
2. Check Prometheus has data for the queried metrics:
   - Use Prometheus UI to execute the same queries
3. Adjust time range in Grafana dashboard
4. Reload the dashboard or clear browser cache

---

## Maintenance

### Backup Procedures

**Jenkins Backup**:

To backup Jenkins configuration:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP>
sudo tar -czf /tmp/jenkins_backup_$(date +%Y%m%d).tar.gz /var/lib/jenkins
sudo aws s3 cp /tmp/jenkins_backup_$(date +%Y%m%d).tar.gz s3://your-backup-bucket/jenkins/
```

**Database Backups**:

For SonarQube's PostgreSQL database:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<SonarQube-EC2-IP>
sudo -u postgres pg_dump sonarqube > /tmp/sonarqube_db_$(date +%Y%m%d).sql
sudo aws s3 cp /tmp/sonarqube_db_$(date +%Y%m%d).sql s3://your-backup-bucket/sonarqube/
```

**Nexus Backup**:

To backup Nexus data:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Nexus-EC2-IP>
sudo systemctl stop nexus
sudo tar -czf /tmp/nexus_backup_$(date +%Y%m%d).tar.gz /opt/sonatype-work
sudo systemctl start nexus
sudo aws s3 cp /tmp/nexus_backup_$(date +%Y%m%d).tar.gz s3://your-backup-bucket/nexus/
```

### Updating Components

**Jenkins Updates**:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP>
sudo yum update jenkins -y
sudo systemctl restart jenkins
```

**SonarQube Updates**:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<SonarQube-EC2-IP>
cd /opt
sudo systemctl stop sonarqube
sudo su - sonar
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.x.y.zip
unzip sonarqube-9.x.y.zip
rm -f /opt/sonarqube
ln -s /opt/sonarqube-9.x.y /opt/sonarqube
chown -R sonar:sonar /opt/sonarqube-9.x.y
exit
sudo systemctl start sonarqube
```

**Nexus Updates**:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Nexus-EC2-IP>
sudo systemctl stop nexus
cd /opt
sudo wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
sudo tar -xzf latest-unix.tar.gz
sudo mv nexus-3.x.y-z /opt/
sudo chown -R nexus:nexus /opt/nexus-3.x.y-z
sudo ln -sf /opt/nexus-3.x.y-z /opt/nexus
sudo systemctl start nexus
```

### Security Maintenance

**Regular Security Updates**:

Apply security updates to all servers regularly:

```bash
ansible all -i infrastructure/ansible/inventory.yml -m yum -a "name=* state=latest" --become
```

**Security Scanning**:

Run Trivy scans periodically to check for vulnerabilities:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Nexus-EC2-IP>
trivy fs --security-checks vuln,config,secret /path/to/application
```

**SSL Certificate Renewal**:

If using HTTPS, ensure certificates are renewed before expiration:

```bash
ssh -i ~/.ssh/DevOpsKey.pem ec2-user@<Jenkins-EC2-IP>
sudo certbot renew
sudo systemctl restart jenkins
```

---

## Security and Credentials Management

### Secure GitHub Credentials with Ansible Vault

To securely manage GitHub credentials for your CI/CD pipeline, we use Ansible Vault to encrypt sensitive information:

#### 1. GitHub Credentials Setup

The pipeline uses a dedicated variables file to store GitHub credentials securely:

```bash
# Navigate to Ansible directory
cd infrastructure/ansible

# Create vars directory if it doesn't exist
mkdir -p vars

# Create GitHub credentials file
cat > vars/github_credentials.yml << 'EOF'
---
# GitHub Credentials - Replace with your actual credentials
# GitHub username for API access
github_username: "your-github-username"

# GitHub personal access token with appropriate permissions
# Required scopes: repo, admin:repo_hook, workflow
github_token: "your-github-personal-access-token"
EOF

# Set appropriate permissions
chmod 600 vars/github_credentials.yml
```

#### 2. Encrypting Credentials with Ansible Vault

Always encrypt the credentials file before committing any changes to version control:

```bash
# Encrypt the credentials file
ansible-vault encrypt infrastructure/ansible/vars/github_credentials.yml

# You will be prompted to create and confirm a vault password
# Remember this password as you'll need it when running the playbook
```

#### 3. Using Encrypted Credentials

When running the Ansible playbook with encrypted credentials:

```bash
# Run playbook with vault password
ansible-playbook -i inventory.yml jenkins-setup.yml --ask-vault-pass

# You will be prompted to enter the vault password you created earlier
```

#### 4. Editing Encrypted Credentials

To modify the encrypted credentials file:

```bash
# Edit the encrypted file
ansible-vault edit infrastructure/ansible/vars/github_credentials.yml

# You will be prompted for the vault password
```

> **Security Note**: The GitHub credentials file is automatically excluded from Git via the `.gitignore` file to prevent accidental exposure of sensitive information.

---

## Quick Reference

### Component Access URLs

| Component   | URL                                  | Default Credentials |
| ----------- | ------------------------------------ | ------------------- |
| Jenkins     | http://<Jenkins-IP>:8080             | Set during setup    |
| SonarQube   | http://<SonarQube-IP>:9000           | admin/admin         |
| Nexus       | http://<Nexus-IP>:8081               | admin/admin123      |
| Prometheus  | http://<Prometheus-IP>:9090          | N/A                 |
| Grafana     | http://<Grafana-IP>:3000             | admin/admin         |
| App (Dev)   | http://<Dev-IP>:8080/java-web-app    | N/A                 |
| App (Build) | http://<Build-IP>:8080/java-web-app  | N/A                 |
| App (Prod)  | http://<Deploy-IP>:8080/java-web-app | N/A                 |

### Common Commands

| Task              | Command                                      |
| ----------------- | -------------------------------------------- |
| Jenkins restart   | `sudo systemctl restart jenkins`             |
| SonarQube restart | `sudo systemctl restart sonarqube`           |
| Nexus restart     | `sudo systemctl restart nexus`               |
| View Jenkins logs | `sudo tail -f /var/log/jenkins/jenkins.log`  |
| View Tomcat logs  | `sudo tail -f /opt/tomcat/logs/catalina.out` |

---

This guide provides comprehensive instructions for setting up, running, and maintaining your Java web application CI/CD pipeline. For additional assistance, please refer to the documentation for individual components or contact the DevOps team.

![Pipeline Footer](https://via.placeholder.com/800x100/0078D7/FFFFFF?text=Java+Web+App+CI/CD+Pipeline)
