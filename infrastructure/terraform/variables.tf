# Define variables for the CI/CD pipeline infrastructure

variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "java-cicd"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "aws_ami" {
  description = "Amazon Linux 2 AMI ID"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Update with the latest Amazon Linux 2 AMI ID
}

variable "instance_types" {
  description = "EC2 instance types for each server"
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

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "DevOpsKey"
}
