# CI/CD Pipeline for Maven Web Application on AWS

## Technical Documentation

**Date:** April 2025  
**Version:** 1.0.0  
**Author:** MaVeN-13TTN

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Infrastructure Components](#infrastructure-components)
4. [CI/CD Pipeline Workflow](#cicd-pipeline-workflow)
5. [Infrastructure Setup](#infrastructure-setup)
6. [GitHub Integration](#github-integration)
7. [Security Features](#security-features)
8. [Monitoring](#monitoring)
9. [Usage Guide](#usage-guide)
10. [Troubleshooting](#troubleshooting)
11. [Contributing](#contributing)
12. [License](#license)

## Project Overview

This project implements a comprehensive CI/CD (Continuous Integration/Continuous Deployment) pipeline for a Maven-based Java web application using GitHub as the source control system. The pipeline is designed to automate the entire software delivery process, from code commit to production deployment, while ensuring code quality, security, and reliability.

### Key Features

- **Source Control**: GitHub repository for version control and collaborative development
- **Automated Build Process**: Automated build and test execution using Jenkins and Maven
- **Code Quality Assurance**: Static code analysis with SonarQube, integrated with GitHub pull requests
- **Security Scanning**: Vulnerability scanning using Trivy
- **Artifact Management**: Centralized artifact repository with Nexus
- **Infrastructure as Code**: AWS infrastructure provisioning with Terraform
- **Configuration Management**: Automated server configuration using Ansible
- **Monitoring and Metrics**: Real-time monitoring with Prometheus and Grafana
- **Multi-environment Support**: Separate development, build, and production environments
- **Manual Approval Gates**: Controlled promotion between environments

## Architecture

This CI/CD pipeline is deployed on AWS and consists of 8 EC2 instances, each serving a specific purpose:

| Instance               | Purpose             | Type      | Description                                                               |
| ---------------------- | ------------------- | --------- | ------------------------------------------------------------------------- |
| Jenkins                | CI/CD Server        | t2.medium | Manages the pipeline execution, builds code, and orchestrates deployments |
| SonarQube              | Code Quality        | t2.medium | Performs static code analysis for the Java application                    |
| Nexus                  | Artifact Repository | t2.medium | Stores built artifacts and dependencies                                   |
| Dev Environment        | Testing Server      | t2.micro  | Hosts the application for development testing                             |
| Build Environment      | Integration Server  | t2.micro  | Environment for integration testing                                       |
| Deployment Environment | Production Server   | t2.micro  | Production-like environment for the application                           |
| Prometheus             | Monitoring          | t2.micro  | Collects metrics from all services and instances                          |
| Grafana                | Visualization       | t2.micro  | Visualizes metrics from Prometheus                                        |

### Network Architecture

- All instances are deployed within a single VPC
- Security groups restrict access between components
- Internet-facing components have proper security constraints
- Internal components are accessible only within the VPC

## Infrastructure Components

### 1. GitHub (Source Control)

GitHub serves as the source control management system, hosting the application code and configuration files.

**Key Features:**

- Collaborative development with pull requests
- Code review process
- Branch protection rules
- Integration with CI/CD pipeline via webhooks
- Issue tracking and project management

**Configuration Details:**

- Protected main branch requiring approved reviews
- Automatic webhook triggers to Jenkins
- GitHub Actions workflow supporting the CI/CD process
- Branch organization following GitFlow principles

### 2. Jenkins (CI/CD Orchestration)

Jenkins serves as the backbone of the CI/CD pipeline, orchestrating the build, test, and deployment process.

**Key Features:**

- Pipeline as Code using Jenkinsfile
- Integration with GitHub for source code management
- Maven for Java application building
- Ansible for deployment automation
- Integration with SonarQube and Nexus

**Configuration Details:**

- Installed on Amazon Linux 2 with Java 11
- Jenkins plugins: Git, GitHub Integration, Pipeline, Maven Integration, Ansible, SonarQube Scanner
- GitHub webhook configuration for automated builds
- Credentials management for secure access to GitHub and other services

### 3. SonarQube (Code Quality)

SonarQube provides continuous code quality inspection, detecting bugs, vulnerabilities, and code smells.

**Key Features:**

- Static code analysis for Java
- Code coverage reporting
- Security vulnerability detection
- Code duplication detection
- Integration with Jenkins pipeline
- Integration with GitHub pull requests for automated code reviews

**Configuration Details:**

- Runs with PostgreSQL database backend
- Customized quality gates and profiles
- Integrated with Jenkins through the SonarQube Scanner plugin

### 4. Nexus Repository (Artifact Management)

Nexus provides a central repository for storing build artifacts and dependencies.

**Key Features:**

- Storage for Maven artifacts
- Version control for built applications
- Dependency proxy for external Maven repositories
- Repository health check
- Role-based access control

**Configuration Details:**

- Configured with Maven release and snapshot repositories
- Integration with Jenkins for artifact deployment
- Security scanning with Trivy

### 5. Ansible (Configuration Management)

Ansible automates the configuration and deployment of applications across the environments.

**Key Features:**

- Infrastructure configuration management
- Application deployment automation
- Idempotent operations
- Playbooks for different services and environments

**Configuration Details:**

- Playbooks for Jenkins, SonarQube, Nexus, and application servers
- Inventory management for multiple environments
- Role-based configuration

### 6. Terraform (Infrastructure as Code)

Terraform manages the AWS infrastructure, ensuring consistent and repeatable provisioning.

**Key Features:**

- Declarative infrastructure definition
- Version-controlled infrastructure
- Resource dependency management
- State management for infrastructure changes

**Configuration Details:**

- AWS provider configuration
- Network infrastructure (VPC, subnets, security groups)
- EC2 instance provisioning
- Output variables for service integration

### 7. Prometheus and Grafana (Monitoring)

Prometheus and Grafana provide real-time monitoring and visualization of system and application metrics.

**Key Features:**

- Real-time metrics collection
- Alert management
- Custom dashboards
- Long-term metrics storage

**Configuration Details:**

- Scrape configurations for all services
- Pre-configured Grafana dashboards
- Alert rules for critical services

## CI/CD Pipeline Workflow

The pipeline follows this workflow:

1. **Code Commit**: Developer pushes code to the GitHub repository or creates a pull request
2. **GitHub Webhook**: GitHub notifies Jenkins of code changes
3. **Build**: Jenkins triggers the pipeline, compiles the code, and runs unit tests
4. **Code Quality Analysis**: SonarQube analyzes the code for quality issues and posts results to GitHub pull requests
5. **Security Scanning**: Trivy scans the codebase and artifacts for vulnerabilities
6. **Artifact Publishing**: Built artifacts are published to Nexus
7. **Deployment to Dev**: Application is automatically deployed to the Dev environment
8. **Approval Gate**: Manual approval required for promoting to Build environment
9. **Deployment to Build**: Application is deployed to the Build environment for integration testing
10. **Approval Gate**: Manual approval required for promoting to Production
11. **Deployment to Production**: Application is deployed to the Production environment

**Pipeline Visualization:**

```
GitHub → Webhook → Jenkins → Build → Quality Analysis → Security Scan → Artifact Publishing
                                                                            ↓
                                                                     Deploy to Dev
                                                                            ↓
                                                                     Manual Approval
                                                                            ↓
                                                                    Deploy to Build
                                                                            ↓
                                                                     Manual Approval
                                                                            ↓
                                                                 Deploy to Production
```

## Infrastructure Setup

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform (v1.0.0+)
- Ansible (v2.9+)
- SSH key pair for EC2 access

### AWS Infrastructure Provisioning

1. **Configure AWS Credentials**:

```bash
aws configure
```

2. **Initialize Terraform**:

```bash
cd infrastructure/terraform
terraform init
```

3. **Review and Customize Infrastructure**:

Edit `terraform.tfvars` to customize instance types, region, and other parameters.

4. **Deploy AWS Infrastructure**:

```bash
terraform plan
terraform apply
```

5. **Note the Output Values**:

Record the output values (IP addresses) for use in the next steps.

### Service Configuration with Ansible

1. **Update Ansible Inventory**:

Update the `infrastructure/ansible/inventory.yml` file with the IP addresses of your EC2 instances.

2. **Set Up Jenkins**:

```bash
cd infrastructure/ansible
ansible-playbook jenkins-setup.yml
```

3. **Set Up SonarQube**:

```bash
ansible-playbook sonarqube-setup.yml
```

4. **Set Up Nexus and Trivy**:

```bash
ansible-playbook nexus-setup.yml
```

5. **Set Up Monitoring**:

```bash
ansible-playbook monitoring-setup.yml
```

## GitHub Integration

### Setting Up GitHub Repository

1. **Create a GitHub Repository**:

   - Create a new repository on GitHub for your Java web application
   - Initialize with a README and .gitignore for Java

2. **Set Up Branch Protection**:

   - Navigate to Settings > Branches in your GitHub repository
   - Add a rule to protect the main branch
   - Require pull request reviews before merging
   - Require status checks to pass before merging

3. **Configure GitHub Webhook**:

   - Go to Settings > Webhooks in your repository
   - Add webhook for your Jenkins server: `http://<Jenkins-IP>:8080/github-webhook/`
   - Select content type: `application/json`
   - Select events: Push, Pull requests, and Pull request reviews

4. **Generate GitHub Access Token**:
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Generate a token with `repo`, `admin:repo_hook`, and `workflow` scopes
   - Save this token securely for Jenkins configuration

### Configure Jenkins for GitHub Integration

1. **Install GitHub Plugins**:

   - GitHub Integration
   - GitHub Branch Source
   - GitHub API

2. **Add GitHub Credentials to Jenkins**:

   - Navigate to Manage Jenkins > Manage Credentials
   - Add credentials of type "Username with password"
   - Use your GitHub username and the access token as password
   - Set ID to "github-credentials"

3. **Configure Jenkins System Settings**:
   - Navigate to Manage Jenkins > Configure System
   - Find GitHub section and add GitHub Server
   - Test connection to verify GitHub integration

### Configure SonarQube for GitHub Integration

1. **Install GitHub Plugin in SonarQube**:

   - Navigate to Administration > Marketplace
   - Find and install the GitHub plugin

2. **Configure GitHub Connection**:
   - Navigate to Administration > Configuration > GitHub
   - Enter your GitHub access token
   - Configure pull request decoration settings

## Security Features

The pipeline includes several security measures:

1. **Code Security Analysis**: SonarQube identifies security vulnerabilities in the code
2. **Vulnerability Scanning**: Trivy scans container images and artifacts for CVEs
3. **Secure Credential Management**: Jenkins credentials store for sensitive information
4. **Network Security**: AWS security groups restrict access between components
5. **Manual Approval Gates**: Human verification before promotion to higher environments
6. **HTTPS Communication**: Encrypted communication between services

## Monitoring

### Prometheus Configuration

The Prometheus server is configured to scrape metrics from:

- Jenkins
- SonarQube
- Nexus
- Application servers
- AWS CloudWatch (via exporters)

### Grafana Dashboards

Pre-configured dashboards are provided for:

- Java Application Metrics
- Server Resource Utilization
- Jenkins Pipeline Statistics
- SonarQube Code Quality Trends

## Usage Guide

### Accessing Services

| Service    | URL                           | Default Credentials                 |
| ---------- | ----------------------------- | ----------------------------------- |
| Jenkins    | http://\<Jenkins-IP\>:8080    | admin/password (change immediately) |
| SonarQube  | http://\<SonarQube-IP\>:9000  | admin/admin (change immediately)    |
| Nexus      | http://\<Nexus-IP\>:8081      | admin/admin123 (change immediately) |
| Prometheus | http://\<Prometheus-IP\>:9090 | N/A                                 |
| Grafana    | http://\<Grafana-IP\>:3000    | admin/admin (change immediately)    |

### Running the Pipeline

1. **Configure Jenkins**:

   - Set up credentials for:
     - GitHub repository access
     - SonarQube token
     - Nexus credentials
   - Update the Jenkins pipeline to point to your GitHub repository

2. **Create a Jenkins Pipeline Job**:

   - Create a new Pipeline job
   - Configure it to use the Jenkinsfile from your GitHub repository
   - Set up GitHub webhook trigger

3. **Execute the Pipeline**:
   - Create a new pull request or push changes to GitHub
   - Monitor the pipeline execution through the Jenkins UI
   - Review SonarQube and Trivy reports
   - Check GitHub for status updates on your pull requests
   - Approve deployments to higher environments

### GitHub Workflow

1. **Development Workflow**:
   - Clone the repository: `git clone https://github.com/MaVeN-13TTN/java-web-app.git`
   - Create a feature branch: `git checkout -b feature/new-feature`
   - Make changes to the code
   - Commit and push changes: `git push origin feature/new-feature`
   - Create a pull request on GitHub
   - Wait for CI pipeline to run and review results
   - Address any issues identified by SonarQube or code reviewers
   - Merge the pull request after approval

## Troubleshooting

### Common Issues

| Issue                                 | Solution                                               |
| ------------------------------------- | ------------------------------------------------------ |
| GitHub webhook not triggering Jenkins | Check webhook configuration and Jenkins connectivity   |
| Jenkins unable to access GitHub repo  | Verify GitHub credentials in Jenkins                   |
| SonarQube not posting to GitHub PRs   | Check SonarQube GitHub integration settings            |
| Jenkins pipeline fails at build stage | Check Maven configuration and application dependencies |
| SonarQube analysis fails              | Verify SonarQube token and connection settings         |
| Nexus artifact upload fails           | Check Nexus credentials and repository configuration   |
| Ansible deployment fails              | Verify SSH access and sudo permissions                 |
| Terraform apply fails                 | Check AWS credentials and resource limits              |

### Logging

- **Jenkins**: Logs available at `/var/log/jenkins/jenkins.log`
- **SonarQube**: Logs available at `/opt/sonarqube/logs/`
- **Nexus**: Logs available at `/opt/nexus/logs/`
- **Application**: Logs available in each environment at `/opt/tomcat/logs/`

## Contributing

1. Fork the repository on GitHub
2. Create a feature branch
3. Make your changes
4. Submit a pull request against the main branch
5. Ensure CI checks pass before merging

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- GitHub for source code hosting
- AWS for infrastructure hosting
- Jenkins, SonarQube, Nexus, and other open-source tools
- The DevOps community for best practices and guidance
