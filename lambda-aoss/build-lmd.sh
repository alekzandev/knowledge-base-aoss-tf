#!/bin/bash

# Lambda Function Deployment Script
set -e

echo "🚀 Starting Lambda function deployment..."

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📂 Script directory: $SCRIPT_DIR"

# Clean up previous builds
echo "🧹 Cleaning up previous builds..."
rm -rf "$SCRIPT_DIR/lambda_package"
rm -f "$SCRIPT_DIR/lambda_function.zip"

# Create package directory
mkdir -p "$SCRIPT_DIR/lambda_package"
cd "$SCRIPT_DIR/lambda_package"

# Copy source files
echo "📋 Copying source files..."
cp -r "$SCRIPT_DIR/lambda_function/" . || {
    echo "❌ Failed to copy source files!"
    exit 1
}

# Install dependencies with proper target and platform
echo "📦 Installing Python dependencies..."
pip install \
    --target . \
    --platform linux_x86_64 \
    --implementation cp \
    --python-version 3.11 \
    --only-binary=:all: \
    --upgrade \
    -r requirements.txt

# Remove unnecessary files to reduce package size
echo "🧹 Cleaning up unnecessary files..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true
find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

# List contents to verify
echo "📋 Package contents:"
ls -la

# Verify critical modules exist
echo "🔍 Verifying critical modules..."
if [ ! -d "opensearchpy" ] && [ ! -d "opensearch_py" ]; then
    echo "❌ opensearch-py not found in package!"
    find . -name "*opensearch*" -type d
    exit 1
fi

if [ ! -d "requests_aws4auth" ]; then
    echo "❌ requests-aws4auth not found in package!"
    exit 1
fi

echo "✅ All required modules found"

# Create deployment package
echo "📦 Creating deployment package..."
echo "📂 Current directory: $(pwd)"
zip -rq "$SCRIPT_DIR/lambda_function.zip" "." -x "requirements.txt"

echo "✅ Lambda deployment package created: lambda_function.zip"
echo "📏 Package size: $(du -h "$SCRIPT_DIR/lambda_function.zip" | cut -f1)"

# Cleanup
cd "$SCRIPT_DIR"
echo "🎉 Deployment package ready!"