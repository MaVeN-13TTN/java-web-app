#!/bin/bash
# build.sh - Script to build the Maven application

set -e  # Exit immediately if a command exits with a non-zero status

echo "===== Starting build process ====="

# Clean previous builds
echo "Cleaning previous builds..."
mvn clean

# Compile the code
echo "Compiling code..."
mvn compile

# Run unit tests
echo "Running unit tests..."
mvn test

# Package the application
echo "Packaging application..."
mvn package

echo "===== Build completed successfully ====="

# Path to the generated WAR file
WAR_FILE=$(find target -name "*.war" | head -1)

if [ -n "$WAR_FILE" ]; then
    echo "WAR file created at: $WAR_FILE"
    echo "Build size: $(du -h $WAR_FILE | cut -f1)"
else
    echo "ERROR: WAR file not found!"
    exit 1
fi