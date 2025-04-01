#!/bin/bash
# quality.sh - Script to run SonarQube analysis

set -e  # Exit immediately if a command exits with a non-zero status

echo "===== Starting code quality analysis with SonarQube ====="

# Check if SONAR_TOKEN is set
if [ -z "$SONAR_TOKEN" ]; then
    echo "ERROR: SONAR_TOKEN environment variable not set!"
    echo "Please set the SonarQube authentication token."
    exit 1
fi

# Check if SONAR_HOST_URL is set
if [ -z "$SONAR_HOST_URL" ]; then
    echo "SONAR_HOST_URL not set, using default: http://localhost:9000"
    SONAR_HOST_URL="http://localhost:9000"
fi

# Check for GitHub environment variables
if [ -n "$GITHUB_REPOSITORY" ] && [ -n "$GITHUB_REF" ]; then
    echo "GitHub environment detected, configuring for GitHub integration..."
    
    # Extract PR number if this is a pull request
    if [[ "$GITHUB_REF" == refs/pull/* ]]; then
        PR_NUMBER=$(echo $GITHUB_REF | sed 's/refs\/pull\/\([0-9]*\)\/merge/\1/')
        echo "Running analysis for Pull Request #$PR_NUMBER"
        
        # Run SonarQube analysis for Pull Request
        mvn sonar:sonar \
          -Dsonar.projectKey=java-web-app \
          -Dsonar.host.url=$SONAR_HOST_URL \
          -Dsonar.login=$SONAR_TOKEN \
          -Dsonar.pullrequest.key=$PR_NUMBER \
          -Dsonar.pullrequest.branch=$GITHUB_HEAD_REF \
          -Dsonar.pullrequest.base=$GITHUB_BASE_REF \
          -Dsonar.pullrequest.github.repository=$GITHUB_REPOSITORY
    else
        # Extract branch name
        BRANCH_NAME=${GITHUB_REF#refs/heads/}
        echo "Running analysis for branch: $BRANCH_NAME"
        
        # Run SonarQube analysis for regular branch
        mvn sonar:sonar \
          -Dsonar.projectKey=java-web-app \
          -Dsonar.host.url=$SONAR_HOST_URL \
          -Dsonar.login=$SONAR_TOKEN \
          -Dsonar.branch.name=$BRANCH_NAME
    fi
else
    # Run standard SonarQube analysis without GitHub integration
    echo "Running standard SonarQube analysis..."
    mvn sonar:sonar \
      -Dsonar.projectKey=java-web-app \
      -Dsonar.host.url=$SONAR_HOST_URL \
      -Dsonar.login=$SONAR_TOKEN
fi

echo "===== SonarQube analysis completed ====="