# Define variables for the CI/CD pipeline infrastructure

variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the primary subnet"
  default     = "us-east-1a"
}

variable "aws_ami" {
  description = "AMI ID to use for EC2 instances - Amazon Linux 2023"
  default     = "ami-05d9b53b86dec19c8" # Amazon Linux 2023
}

variable "key_name" {
  description = "SSH key name to use for EC2 instances"
  default     = "DevOpsKey"
}

variable "project_name" {
  description = "Name of the project"
  default     = "java-cicd"
}

variable "instance_types" {
  description = "Instance types for each server"
  type        = map(string)
  default = {
    jenkins    = "t2.medium"
    sonarqube  = "t2.medium"
    nexus      = "t2.medium"
    dev        = "t2.micro"
    build      = "t2.micro"
    deploy     = "t2.micro"
    prometheus = "t2.micro"
    grafana    = "t2.micro"
  }
}

# Security group variables for refined security controls
variable "admin_cidr_blocks" {
  description = "CIDR blocks for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # In production, this should be restricted to VPN or admin IP ranges
}

variable "github_webhook_cidr_blocks" {
  description = "CIDR blocks for GitHub webhook access"
  type        = list(string)
  default = [
    "192.30.252.0/22",  # GitHub webhooks
    "185.199.108.0/22", # GitHub webhooks
    "140.82.112.0/20",  # GitHub webhooks
    "143.55.64.0/20"    # GitHub webhooks
  ]
}

variable "app_access_cidr_blocks" {
  description = "CIDR blocks for application access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # In production, this could be more restricted
}
