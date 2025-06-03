# Quick Start Guide - OpenSearch AI Chatbot

Get your AI chatbot infrastructure running with OpenSearch Serverless vector database in minutes.

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.5** installed
3. **Python 3.11** for Lambda function development
4. **Amazon Bedrock access** enabled in your AWS account

## Step 1: Clone and Explore

```bash
# Navigate to your project directory
cd /path/to/your/project

# Explore the module structure
tree modules/
```

The architecture prioritizes:
- **OpenSearch Serverless** (`modules/opensearch-vector-db/`) - Primary vector database
- **Lambda AI Execution** (`modules/lambda-ai-execution/`) - Serverless AI processing
- **S3 Storage** (`modules/s3-vector-storage/`) - Optional backup storage

## Step 2: Configure Variables

```bash
# Copy the example variables file
cd examples/
cp terraform.tfvars.example terraform.tfvars

# Edit the variables for your environment
vim terraform.tfvars
```

**Key Configuration**:
```hcl
# OpenSearch Configuration (Primary)
opensearch_collection_name = "my-ai-chatbot"
opensearch_vector_dimension = 1536

# AI Model Configuration
bedrock_embedding_model_id = "amazon.titan-embed-text-v1"
bedrock_text_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

# Optional S3 backup
s3_backup_enabled = false  # Enable for interaction logging
```

## Step 3: Prepare Lambda Function

```bash
# Package the Lambda function with OpenSearch dependencies
./deploy-lambda.sh

# This creates lambda_function.zip with opensearch-py and dependencies
```

## Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment (review OpenSearch and Lambda resources)
terraform plan

# Apply the configuration
terraform apply
```

## Step 5: Test the OpenSearch Integration

```bash
# Get the outputs from Terraform
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
OPENSEARCH_ENDPOINT=$(terraform output -raw opensearch_endpoint)

# Test the Lambda function with OpenSearch
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{"query": "What is artificial intelligence?", "user_id": "test-user"}' \
  response.json

# View the response with vector search results
cat response.json | jq '.'
```

## Example Response

```json
{
  "answer": "Artificial intelligence (AI) refers to...",
  "context_sources": [
    {
      "id": "doc-123",
      "score": 0.89,
      "title": "Introduction to AI"
    }
  ],
  "interaction_id": "int-456",
  "timestamp": "2025-05-31T10:30:00Z",
  "chunk_count": 2
}
```

## Example Usage Snippets

### OpenSearch Vector Database Module (Primary)

```hcl
module "opensearch_vectordb" {
  source = "./modules/opensearch-vector-db"
  
  collection_name = "ai-chatbot-vectors"
  project_name    = "my-ai-project"
  environment     = "prod"
  
  # Vector configuration
  vector_dimension     = 1536
  similarity_metric    = "cosine"
  vector_engine        = "nmslib"
  
  # Security
  enable_public_access = false
  vpc_id              = "vpc-12345678"
  private_subnet_ids  = ["subnet-abc", "subnet-def"]
  
  tags = {
    Team = "AI-Engineering"
  }
}
```

### Lambda AI Execution Module

```hcl
module "ai_lambda" {
  source = "./modules/lambda-ai-execution"
  
  project_name  = "my-ai-project"
  environment   = "prod"
  function_name = "chatbot-inference"
  
  runtime     = "python3.11"
  timeout     = 300
  memory_size = 3008
  
  # OpenSearch integration
  opensearch_endpoint        = module.opensearch_vectordb.collection_endpoint
  opensearch_collection_name = module.opensearch_vectordb.collection_name
  opensearch_vector_dimension = 1536
  
  # AI model configuration
  bedrock_embedding_model_id = "amazon.titan-embed-text-v1"
  bedrock_text_model_id     = "anthropic.claude-3-sonnet-20240229-v1:0"
  
  # Optional S3 backup
  s3_bucket_name = module.vector_storage.bucket_name  # if enabled
}
```

### Optional S3 Backup Storage Module

```hcl
module "vector_storage" {
  source = "./modules/s3-vector-storage"
  
  project_name = "my-ai-project"
  environment  = "prod"
  
  enable_versioning  = true
  enable_replication = false  # Enable for production
  
  tags = {
    Team = "AI-Engineering"
    Purpose = "Backup"
  }
}
```

## Next Steps

1. **Index your data**: Upload documents to OpenSearch for vector search
2. **Configure monitoring**: Set up CloudWatch dashboards and alerts  
3. **Add API Gateway**: Create REST API endpoints for your chatbot
4. **Implement CI/CD**: Set up automated deployment pipelines
5. **Scale**: Configure provisioned concurrency and auto-scaling

## Data Indexing

After deployment, you'll need to index your knowledge base:

```python
# Example: Index documents into OpenSearch
import boto3
from opensearchpy import OpenSearch
from aws_requests_auth.aws_auth import AWSRequestsAuth

# Initialize clients
bedrock = boto3.client('bedrock-runtime')
opensearch_client = OpenSearch(
    hosts=[{'host': 'your-collection-endpoint', 'port': 443}],
    http_auth=AWSRequestsAuth(boto3.Session().get_credentials(), 'us-east-1', 'aoss'),
    use_ssl=True,
    verify_certs=True
)

# Index a document with vector embedding
def index_document(text, title):
    # Generate embedding
    response = bedrock.invoke_model(
        modelId='amazon.titan-embed-text-v1',
        body=json.dumps({"inputText": text})
    )
    embedding = json.loads(response['body'].read())['embedding']
    
    # Index document
    doc = {
        'content': text,
        'title': title,
        'content_vector': embedding,
        'timestamp': datetime.utcnow().isoformat()
    }
    
    opensearch_client.index(
        index='knowledge-base',
        body=doc
    )
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your AWS credentials have sufficient permissions
2. **Resource Limits**: Check AWS service quotas for your region
3. **Network Issues**: Verify VPC configuration if using private subnets

### Useful Commands

```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# View logs
aws logs tail /aws/lambda/your-function-name --follow
```
