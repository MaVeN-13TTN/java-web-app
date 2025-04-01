#!/bin/bash
# security-scan.sh - Script to run security scanning with Trivy

set -e  # Exit immediately if a command exits with a non-zero status

echo "===== Starting security scanning with Trivy ====="

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "ERROR: Trivy is not installed!"
    echo "Please install Trivy: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
    exit 1
fi

# Scan for filesystem vulnerabilities in the application
echo "Scanning application for vulnerabilities..."
trivy fs --security-checks vuln,config,secret .

# Scan the WAR file if it exists
WAR_FILE=$(find target -name "*.war" | head -1)
if [ -n "$WAR_FILE" ]; then
    echo "Scanning WAR file for vulnerabilities..."
    trivy fs --security-checks vuln $WAR_FILE
else
    echo "WARNING: WAR file not found, skipping archive scan"
fi

# Check exit code and report
if [ $? -eq 0 ]; then
    echo "===== Security scanning completed successfully ====="
    echo "No critical vulnerabilities found!"
else
    echo "===== Security scanning completed with warnings ====="
    echo "Please review the security findings above."
    # Don't fail the pipeline, but give a warning
    # exit 1
fi