#!/bin/bash
# update_ip_addresses.sh - Script to automatically update configuration files with EC2 IP addresses from Terraform

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/infrastructure/terraform"
ANSIBLE_INVENTORY="${PROJECT_ROOT}/infrastructure/ansible/inventory.yml"
JENKINSFILE="${PROJECT_ROOT}/pipeline/Jenkinsfile"
GITHUB_WORKFLOW="${PROJECT_ROOT}/.github/workflows/ci-cd.yml"
PROMETHEUS_CONFIG="${PROJECT_ROOT}/monitoring/prometheus/prometheus.yml"
README="${PROJECT_ROOT}/README.md"

echo "===== Automated IP Address Configuration Tool ====="
echo "Date: $(date)"
echo "Updating configuration files with EC2 IP addresses from Terraform outputs"

# Function to check if Terraform state exists
check_terraform_state() {
    if [ ! -f "${TERRAFORM_DIR}/terraform.tfstate" ]; then
        echo "ERROR: Terraform state file not found at ${TERRAFORM_DIR}/terraform.tfstate"
        echo "Please run 'terraform apply' in the terraform directory first."
        exit 1
    fi
}

# Function to retrieve Terraform outputs
get_terraform_output() {
    local output_name=$1
    cd "${TERRAFORM_DIR}"
    terraform output -raw "${output_name}" 2>/dev/null || echo "not-available"
}

# Collect all IP addresses from Terraform outputs
collect_ip_addresses() {
    echo "Collecting IP addresses from Terraform outputs..."
    
    JENKINS_IP=$(get_terraform_output jenkins_public_ip)
    SONARQUBE_IP=$(get_terraform_output sonarqube_public_ip)
    NEXUS_IP=$(get_terraform_output nexus_public_ip)
    DEV_IP=$(get_terraform_output dev_public_ip)
    BUILD_IP=$(get_terraform_output build_public_ip)
    DEPLOY_IP=$(get_terraform_output deploy_public_ip)
    PROMETHEUS_IP=$(get_terraform_output prometheus_public_ip)
    GRAFANA_IP=$(get_terraform_output grafana_public_ip)
    
    # Display collected IP addresses
    echo "Jenkins IP: ${JENKINS_IP}"
    echo "SonarQube IP: ${SONARQUBE_IP}"
    echo "Nexus IP: ${NEXUS_IP}"
    echo "Dev Environment IP: ${DEV_IP}"
    echo "Build Environment IP: ${BUILD_IP}"
    echo "Deployment Environment IP: ${DEPLOY_IP}"
    echo "Prometheus IP: ${PROMETHEUS_IP}"
    echo "Grafana IP: ${GRAFANA_IP}"
}

# Update Ansible inventory file
update_ansible_inventory() {
    echo "Updating Ansible inventory file..."
    
    if [ -f "${ANSIBLE_INVENTORY}" ]; then
        # Create a backup of the original file
        cp "${ANSIBLE_INVENTORY}" "${ANSIBLE_INVENTORY}.bak"
        
        # Replace placeholders with actual IP addresses
        sed -i "s/<Jenkins-EC2-IP>/${JENKINS_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<SonarQube-EC2-IP>/${SONARQUBE_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<Nexus-EC2-IP>/${NEXUS_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<Dev-Environment-EC2-IP>/${DEV_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<Build-Environment-EC2-IP>/${BUILD_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<Deployment-Environment-EC2-IP>/${DEPLOY_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<Prometheus-EC2-IP>/${PROMETHEUS_IP}/g" "${ANSIBLE_INVENTORY}"
        sed -i "s/<Grafana-EC2-IP>/${GRAFANA_IP}/g" "${ANSIBLE_INVENTORY}"
        
        echo "✅ Ansible inventory updated successfully"
    else
        echo "⚠️ Ansible inventory file not found at ${ANSIBLE_INVENTORY}"
    fi
}

# Update Jenkinsfile
update_jenkinsfile() {
    echo "Updating Jenkinsfile..."
    
    if [ -f "${JENKINSFILE}" ]; then
        # Create a backup of the original file
        cp "${JENKINSFILE}" "${JENKINSFILE}.bak"
        
        # Replace placeholders with actual IP addresses
        sed -i "s/<Nexus-EC2-IP>/${NEXUS_IP}/g" "${JENKINSFILE}"
        sed -i "s/<SonarQube-EC2-IP>/${SONARQUBE_IP}/g" "${JENKINSFILE}"
        
        echo "✅ Jenkinsfile updated successfully"
    else
        echo "⚠️ Jenkinsfile not found at ${JENKINSFILE}"
    fi
}

# Update GitHub workflow file
update_github_workflow() {
    echo "Updating GitHub workflow file..."
    
    if [ -f "${GITHUB_WORKFLOW}" ]; then
        # Create a backup of the original file
        cp "${GITHUB_WORKFLOW}" "${GITHUB_WORKFLOW}.bak"
        
        # Replace placeholders with actual IP addresses
        sed -i "s/<Jenkins-EC2-IP>/${JENKINS_IP}/g" "${GITHUB_WORKFLOW}"
        
        echo "✅ GitHub workflow file updated successfully"
    else
        echo "⚠️ GitHub workflow file not found at ${GITHUB_WORKFLOW}"
    fi
}

# Update Prometheus configuration
update_prometheus_config() {
    echo "Updating Prometheus configuration..."
    
    if [ -f "${PROMETHEUS_CONFIG}" ]; then
        # Create a backup of the original file
        cp "${PROMETHEUS_CONFIG}" "${PROMETHEUS_CONFIG}.bak"
        
        # Replace placeholders with actual IP addresses
        sed -i "s/<Jenkins-EC2-IP>/${JENKINS_IP}/g" "${PROMETHEUS_CONFIG}"
        sed -i "s/<SonarQube-EC2-IP>/${SONARQUBE_IP}/g" "${PROMETHEUS_CONFIG}"
        sed -i "s/<Nexus-EC2-IP>/${NEXUS_IP}/g" "${PROMETHEUS_CONFIG}"
        
        echo "✅ Prometheus configuration updated successfully"
    else
        echo "⚠️ Prometheus configuration not found at ${PROMETHEUS_CONFIG}"
    fi
}

# Update README.md for documentation
update_readme() {
    echo "Updating README.md with IP addresses for documentation..."
    
    if [ -f "${README}" ]; then
        # Create a backup of the original file
        cp "${README}" "${README}.bak"
        
        # Generate a table of service URLs for reference
        README_SERVICES_TABLE="
| Service    | URL                                  | Default Credentials                 |
| ---------- | ------------------------------------ | ----------------------------------- |
| Jenkins    | http://${JENKINS_IP}:8080            | admin/password (change immediately) |
| SonarQube  | http://${SONARQUBE_IP}:9000          | admin/admin (change immediately)    |
| Nexus      | http://${NEXUS_IP}:8081              | admin/admin123 (change immediately) |
| Prometheus | http://${PROMETHEUS_IP}:9090         | N/A                                 |
| Grafana    | http://${GRAFANA_IP}:3000            | admin/admin (change immediately)    |
"
        
        # Replace the placeholder URLs table and webhook URL in README with actual values
        sed -i "s|http://<Jenkins-IP>:8080/github-webhook/|http://${JENKINS_IP}:8080/github-webhook/|g" "${README}"
        
        # Look for the services table and replace it with our generated one
        # This is more complex, so we create a marker file and use awk
        awk -v replace="${README_SERVICES_TABLE}" '
        /\| Service    \| URL                           \| Default Credentials                 \|/ {
            print replace;
            skip = 1;
            next;
        }
        /\| ---------- \| ----------------------------- \| ----------------------------------- \|/ { skip = 1; next; }
        /\| Jenkins    \| http/ { skip = 1; next; }
        /\| SonarQube  \| http/ { skip = 1; next; }
        /\| Nexus      \| http/ { skip = 1; next; }
        /\| Prometheus \| http/ { skip = 1; next; }
        /\| Grafana    \| http/ { skip = 1; next; }
        { if (!skip) print; else skip = 0; }
        ' "${README}" > "${README}.new"
        
        mv "${README}.new" "${README}"
        
        echo "✅ README.md updated successfully with service URLs"
    else
        echo "⚠️ README.md not found at ${README}"
    fi
}

# Verify all placeholder values have been replaced
verify_no_placeholders() {
    echo "Verifying all placeholder values have been replaced..."
    
    # List of files to check
    files_to_check=(
        "${ANSIBLE_INVENTORY}"
        "${JENKINSFILE}"
        "${GITHUB_WORKFLOW}"
        "${PROMETHEUS_CONFIG}"
    )
    
    all_placeholders_replaced=true
    
    for file in "${files_to_check[@]}"; do
        if [ -f "${file}" ]; then
            placeholders=$(grep -c "<.*-EC2-IP>" "${file}" || true)
            
            if [ "$placeholders" -gt 0 ]; then
                echo "⚠️ File ${file} still contains ${placeholders} placeholder(s)"
                all_placeholders_replaced=false
            fi
        fi
    done
    
    if [ "$all_placeholders_replaced" = true ]; then
        echo "✅ All placeholder values have been successfully replaced"
    else
        echo "⚠️ Some placeholder values still remain. Please check the output above."
    fi
}

# Generate a summary report
generate_summary_report() {
    echo "Generating summary report..."
    
    SUMMARY_FILE="${PROJECT_ROOT}/ip_address_update_summary.txt"
    
    echo "==========================================" > "${SUMMARY_FILE}"
    echo "CI/CD Infrastructure IP Address Summary" >> "${SUMMARY_FILE}"
    echo "==========================================" >> "${SUMMARY_FILE}"
    echo "Generated: $(date)" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
    echo "Server IP Addresses:" >> "${SUMMARY_FILE}"
    echo "-----------------" >> "${SUMMARY_FILE}"
    echo "Jenkins: ${JENKINS_IP}" >> "${SUMMARY_FILE}"
    echo "SonarQube: ${SONARQUBE_IP}" >> "${SUMMARY_FILE}"
    echo "Nexus: ${NEXUS_IP}" >> "${SUMMARY_FILE}"
    echo "Dev Environment: ${DEV_IP}" >> "${SUMMARY_FILE}"
    echo "Build Environment: ${BUILD_IP}" >> "${SUMMARY_FILE}"
    echo "Deployment Environment: ${DEPLOY_IP}" >> "${SUMMARY_FILE}"
    echo "Prometheus: ${PROMETHEUS_IP}" >> "${SUMMARY_FILE}"
    echo "Grafana: ${GRAFANA_IP}" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
    echo "Service URLs:" >> "${SUMMARY_FILE}"
    echo "-------------" >> "${SUMMARY_FILE}"
    echo "Jenkins: http://${JENKINS_IP}:8080" >> "${SUMMARY_FILE}"
    echo "SonarQube: http://${SONARQUBE_IP}:9000" >> "${SUMMARY_FILE}"
    echo "Nexus: http://${NEXUS_IP}:8081" >> "${SUMMARY_FILE}"
    echo "Prometheus: http://${PROMETHEUS_IP}:9090" >> "${SUMMARY_FILE}"
    echo "Grafana: http://${GRAFANA_IP}:3000" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
    echo "GitHub Webhook URL: http://${JENKINS_IP}:8080/github-webhook/" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
    echo "Updated Files:" >> "${SUMMARY_FILE}"
    echo "--------------" >> "${SUMMARY_FILE}"
    echo "- Ansible Inventory: ${ANSIBLE_INVENTORY}" >> "${SUMMARY_FILE}"
    echo "- Jenkinsfile: ${JENKINSFILE}" >> "${SUMMARY_FILE}"
    echo "- GitHub Workflow: ${GITHUB_WORKFLOW}" >> "${SUMMARY_FILE}"
    echo "- Prometheus Config: ${PROMETHEUS_CONFIG}" >> "${SUMMARY_FILE}"
    echo "- README.md: ${README}" >> "${SUMMARY_FILE}"
    echo "" >> "${SUMMARY_FILE}"
    echo "Backup files have been created with .bak extension" >> "${SUMMARY_FILE}"
    echo "==========================================" >> "${SUMMARY_FILE}"
    
    echo "✅ Summary report generated at ${SUMMARY_FILE}"
}

# Main execution
main() {
    check_terraform_state
    collect_ip_addresses
    update_ansible_inventory
    update_jenkinsfile
    update_github_workflow
    update_prometheus_config
    update_readme
    verify_no_placeholders
    generate_summary_report
    
    echo ""
    echo "===== IP Address Configuration Complete ====="
    echo "All configuration files have been updated with EC2 IP addresses."
    echo "Backup files have been created with .bak extension."
    echo "A summary report has been generated at ${PROJECT_ROOT}/ip_address_update_summary.txt"
    echo ""
    echo "Next Steps:"
    echo "1. Review the updated files to ensure all placeholders were replaced correctly"
    echo "2. Run Ansible playbooks to configure the servers:"
    echo "   cd infrastructure/ansible"
    echo "   ansible-playbook jenkins-setup.yml"
    echo "   ansible-playbook sonarqube-setup.yml"
    echo "   ansible-playbook nexus-setup.yml"
    echo "   ansible-playbook monitoring-setup.yml"
    echo ""
}

# Execute main function
main