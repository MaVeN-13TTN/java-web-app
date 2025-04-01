# Output variables for the CI/CD pipeline infrastructure

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "sonarqube_public_ip" {
  description = "Public IP address of the SonarQube server"
  value       = aws_instance.sonarqube.public_ip
}

output "nexus_public_ip" {
  description = "Public IP address of the Nexus server"
  value       = aws_instance.nexus.public_ip
}

output "dev_public_ip" {
  description = "Public IP address of the Dev environment"
  value       = aws_instance.dev.public_ip
}

output "build_public_ip" {
  description = "Public IP address of the Build environment"
  value       = aws_instance.build.public_ip
}

output "deploy_public_ip" {
  description = "Public IP address of the Deployment environment"
  value       = aws_instance.deploy.public_ip
}

output "prometheus_public_ip" {
  description = "Public IP address of the Prometheus server"
  value       = aws_instance.prometheus.public_ip
}

output "grafana_public_ip" {
  description = "Public IP address of the Grafana server"
  value       = aws_instance.grafana.public_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.main.id
}
