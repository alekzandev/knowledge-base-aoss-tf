#!/bin/bash

# Lambda Function Deployment Script
# This script packages and deploys the Lambda function

set -e

echo "🚀 Starting Lambda function deployment..."

# Create a temporary directory for packaging
TEMP_DIR=$(mktemp -d)
echo "📦 Using temporary directory: $TEMP_DIR"

# Copy source files
cp -r lambda-src/* "$TEMP_DIR/"
cd "$TEMP_DIR"

# Install dependencies (if requirements.txt exists)
if [ -f "requirements.txt" ]; then
    echo "📋 Installing Python dependencies..."
    pip install --target . -r requirements.txt
fi

# Create deployment package
echo "📦 Creating deployment package..."
zip -r ../lambda_function.zip . -x "*.pyc" "*__pycache__*" "*.git*"

# Move the package back
mv ../lambda_function.zip ../lambda_function.zip

echo "✅ Lambda deployment package created: lambda_function.zip"
echo "💡 Upload this file to S3 or use it directly with Terraform"

# Cleanup
cd ..
rm -rf "$TEMP_DIR"

echo "🎉 Deployment package ready!"
