# Default variable values for the CI/CD pipeline infrastructure

aws_region        = "us-east-1"
project_name      = "java-cicd"
vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"
availability_zone = "us-east-1a"
aws_ami           = "ami-05d9b53b86dec19c8" # Amazon Linux 2023 AMI
key_name          = "DevOpsKey"

# Instance types configuration
instance_types = {
  jenkins    = "t2.medium"
  sonarqube  = "t2.medium"
  nexus      = "t2.medium"
  dev        = "t2.micro"
  build      = "t2.micro"
  deploy     = "t2.micro"
  prometheus = "t2.micro"
  grafana    = "t2.micro"
}
