# Terraform configuration for AWS infrastructure

provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Create Security Group for Administrative SSH access
resource "aws_security_group" "admin_ssh" {
  name        = "admin_ssh"
  description = "Allow SSH from admin IPs only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "SSH access from admin IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-admin-ssh"
  }
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Allow Jenkins traffic"
  vpc_id      = aws_vpc.main.id

  # Allow Jenkins web access from admin IPs
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "Jenkins web UI access"
  }

  # Allow GitHub webhook traffic
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.github_webhook_cidr_blocks
    description = "GitHub webhook access"
  }

  # Allow Jenkins agent communication
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "Jenkins agent communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-jenkins"
  }
}

# Security Group for SonarQube
resource "aws_security_group" "sonarqube" {
  name        = "sonarqube"
  description = "Allow SonarQube traffic"
  vpc_id      = aws_vpc.main.id

  # Allow SonarQube web access from admin IPs
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "SonarQube web UI access"
  }

  # Allow Jenkins to SonarQube communication
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "Jenkins to SonarQube communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-sonarqube"
  }
}

# Security Group for Nexus
resource "aws_security_group" "nexus" {
  name        = "nexus"
  description = "Allow Nexus traffic"
  vpc_id      = aws_vpc.main.id

  # Allow Nexus web access from admin IPs
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "Nexus web UI access"
  }

  # Allow Jenkins to Nexus communication
  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "Jenkins to Nexus communication"
  }

  # Allow app servers to Nexus for artifact downloads
  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "App servers to Nexus for artifact downloads"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-nexus"
  }
}

# Security Group for Prometheus and Grafana
resource "aws_security_group" "monitoring" {
  name        = "monitoring"
  description = "Allow monitoring traffic"
  vpc_id      = aws_vpc.main.id

  # Allow Prometheus UI access from admin IPs
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "Prometheus web UI access"
  }

  # Allow Grafana UI access from admin IPs
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "Grafana web UI access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-monitoring"
  }
}

# Security Group for Web Applications
resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow web application traffic"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP access to web applications
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.app_access_cidr_blocks
    description = "Web application access"
  }

  # Allow Jenkins to web servers communication
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "Jenkins to web servers communication"
  }

  # Allow Prometheus to scrape metrics
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
    description     = "Prometheus metrics scraping"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-web"
  }
}

# Security Group for metrics exporters
resource "aws_security_group" "metrics" {
  name        = "metrics"
  description = "Allow metrics collection"
  vpc_id      = aws_vpc.main.id

  # Allow Prometheus to scrape node_exporter
  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
    description     = "Prometheus to node_exporter"
  }

  # Allow Prometheus to scrape Java metrics
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
    description     = "Prometheus to JMX exporter"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-metrics"
  }
}

# Security Group for Trivy security scanning
resource "aws_security_group" "trivy" {
  name        = "trivy"
  description = "Allow Trivy security scanning"
  vpc_id      = aws_vpc.main.id

  # Allow Jenkins to Trivy communication
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "Jenkins to Trivy SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg-trivy"
  }
}

# Create Jenkins EC2 Instance with updated security groups
resource "aws_instance" "jenkins" {
  ami           = var.aws_ami
  instance_type = var.instance_types["jenkins"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.jenkins.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Jenkins-Server"
  }
}

# Create SonarQube EC2 Instance with updated security groups
resource "aws_instance" "sonarqube" {
  ami           = var.aws_ami
  instance_type = var.instance_types["sonarqube"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.sonarqube.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "SonarQube-Server"
  }
}

# Create Nexus EC2 Instance with updated security groups
resource "aws_instance" "nexus" {
  ami           = var.aws_ami
  instance_type = var.instance_types["nexus"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.nexus.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Nexus-Server"
  }
}

# Create Dev Environment EC2 Instance with updated security groups
resource "aws_instance" "dev" {
  ami           = var.aws_ami
  instance_type = var.instance_types["dev"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.web.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Dev-Environment"
  }
}

# Create Build Environment EC2 Instance with updated security groups
resource "aws_instance" "build" {
  ami           = var.aws_ami
  instance_type = var.instance_types["build"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.web.id,
    aws_security_group.metrics.id,
    aws_security_group.trivy.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Build-Environment"
  }
}

# Create Deployment Environment EC2 Instance with updated security groups
resource "aws_instance" "deploy" {
  ami           = var.aws_ami
  instance_type = var.instance_types["deploy"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.web.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Deployment-Environment"
  }
}

# Create Prometheus EC2 Instance with updated security groups
resource "aws_instance" "prometheus" {
  ami           = var.aws_ami
  instance_type = var.instance_types["prometheus"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.monitoring.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Prometheus-Server"
  }
}

# Create Grafana EC2 Instance with updated security groups
resource "aws_instance" "grafana" {
  ami           = var.aws_ami
  instance_type = var.instance_types["grafana"]
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.admin_ssh.id,
    aws_security_group.monitoring.id,
    aws_security_group.metrics.id
  ]
  key_name = var.key_name

  tags = {
    Name = "Grafana-Server"
  }
}
