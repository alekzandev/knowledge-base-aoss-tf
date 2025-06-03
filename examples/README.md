# Example: Complete AI Chatbot Infrastructure with OpenSearch

This example demonstrates how to use the OpenSearch Serverless vector database, Lambda AI execution, and optionally S3 backup storage modules together to create a complete AI chatbot infrastructure optimized for near real-time vector search.

## Architecture

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   API Gateway   │───▶│  Lambda Function │───▶│ OpenSearch Serverless│
│                 │    │  (AI Execution)  │    │   (Vector Database) │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                              │                          │
                              ▼                          │
                       ┌──────────────────┐              │
                       │ Amazon Bedrock   │              │
                       │   (LLM Models)   │              │
                       │ - Text Generation│              │
                       │ - Embeddings     │              │
                       └──────────────────┘              │
                              │                          │
                              ▼                          │
                       ┌──────────────────┐              │
                       │   Amazon S3      │◀─────────────┘
                       │ (Optional Backup)│
                       └──────────────────┘
```

## Key Features

- **OpenSearch Serverless**: Primary vector database for near real-time similarity search
- **Vector Search Optimization**: k-NN search with configurable similarity metrics
- **AI Model Integration**: Seamless integration with Amazon Bedrock models
- **Performance Monitoring**: CloudWatch metrics and alarms
- **Security**: IAM policies, encryption, and VPC endpoints
- **Optional S3 Backup**: For interaction logging and data persistence

## Quick Start

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your specific values:
   ```hcl
   # Required: OpenSearch configuration
   opensearch_collection_name = "my-ai-chatbot"
   opensearch_vector_dimension = 1536
   
   # Required: AI model configuration
   bedrock_embedding_model_id = "amazon.titan-embed-text-v1"
   bedrock_text_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
   ```

3. **Deploy the infrastructure**:
   ```bash
   # Initialize Terraform
   terraform init
   
   # Plan the deployment
   terraform plan -var-file="terraform.tfvars"
   
   # Apply the configuration
   terraform apply -var-file="terraform.tfvars"
   ```

## Usage

After deployment, you can test the AI chatbot Lambda function:

```bash
# Deploy the Lambda function code
./deploy-lambda.sh

# Test with a sample request
aws lambda invoke \
  --function-name "$(terraform output -raw lambda_function_name)" \
  --payload '{"query": "What is machine learning?", "user_id": "test-user"}' \
  response.json

# View the response
cat response.json
```

## Example API Usage

```json
{
  "query": "What are the benefits of vector databases?",
  "conversation_id": "conv-123",
  "user_id": "user-456"
}
```

Response:
```json
{
  "answer": "Vector databases offer several benefits...",
  "context_sources": [
    {
      "id": "doc-1",
      "score": 0.92,
      "title": "Vector Database Guide"
    }
  ],
  "interaction_id": "int-789",
  "timestamp": "2025-05-31T10:30:00Z",
  "chunk_count": 3
}
```

## Configuration

### Required Variables

- `opensearch_collection_name`: Name for your OpenSearch Serverless collection
- `opensearch_vector_dimension`: Dimension of your embeddings (e.g., 1536 for Titan)
- `bedrock_embedding_model_id`: Bedrock model for generating embeddings
- `bedrock_text_model_id`: Bedrock model for text generation

### Optional Variables

- `s3_backup_enabled`: Enable S3 backup storage (default: false)
- `lambda_memory_size`: Lambda memory allocation (default: 3008 MB)
- `vector_similarity_threshold`: Minimum similarity score (default: 0.8)

## Monitoring

The infrastructure includes comprehensive monitoring:

- **CloudWatch Metrics**: Request duration, error rates, OpenSearch performance
- **CloudWatch Alarms**: Automatic alerts for high error rates or latency
- **X-Ray Tracing**: Distributed tracing for debugging

Access metrics in CloudWatch under the `AI-Chatbot/Lambda` and `AWS/AOSS` namespaces.

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variable values
- `deploy-lambda.sh` - Lambda deployment script
- `lambda-src/` - Lambda function source code
  - `app.py` - Main application code
  - `requirements.txt` - Python dependencies

## Security Considerations

- OpenSearch collections use IAM-based authentication
- Lambda functions have minimal required permissions
- VPC endpoints available for private network access
- S3 buckets (if enabled) use KMS encryption
- All resources follow AWS security best practices

## Troubleshooting

### Common Issues

1. **OpenSearch Access Denied**: Ensure IAM roles have proper AOSS permissions
2. **Lambda Timeout**: Increase timeout for large document processing
3. **Vector Dimension Mismatch**: Ensure embedding model dimensions match configuration

### Debug Mode

Enable debug logging:
```hcl
log_level = "DEBUG"
```

### Performance Tuning

For production workloads:
- Enable provisioned concurrency for Lambda
- Configure appropriate memory allocation
- Set up VPC endpoints for improved performance
- Use S3 backup for long-term storage
