# Lambda AI Execution Module

This module creates Lambda functions optimized for AI model execution, including integration with Amazon Bedrock, S3 vector storage, and OpenSearch.

## Features

- **Auto-scaling**: Configurable provisioned concurrency and reserved capacity
- **Security**: VPC integration with private subnets and security groups
- **Monitoring**: CloudWatch logs, metrics, and X-Ray tracing
- **Dead Letter Queue**: Error handling and retry mechanisms
- **Environment Variables**: Secure configuration management
- **Layers**: Support for custom AI/ML libraries and dependencies
- **IAM Policies**: Least privilege access to AWS services

## Usage

```hcl
module "ai_lambda" {
  source = "./modules/lambda-ai-execution"
  
  project_name    = "ai-chatbot"
  environment     = "prod"
  function_name   = "model-inference"
  
  # Function configuration
  runtime          = "python3.11"
  handler          = "app.lambda_handler"
  timeout          = 300
  memory_size      = 3008
  
  # Auto-scaling
  provisioned_concurrency_config = {
    provisioned_concurrent_executions = 10
  }
  
  # VPC configuration
  vpc_config = {
    subnet_ids         = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-abcdef"]
  }
  
  # Environment variables
  environment_variables = {
    BEDROCK_REGION     = "us-east-1"
    S3_BUCKET_NAME     = "my-vector-storage-bucket"
    OPENSEARCH_ENDPOINT = "https://search-domain.us-east-1.es.amazonaws.com"
    LOG_LEVEL          = "INFO"
  }
  
  # Dead letter queue
  enable_dlq = true
  
  # CloudWatch logs retention
  log_retention_in_days = 14
  
  # Tags
  tags = {
    Project = "AI-Chatbot"
    Owner   = "ML-Engineering-Team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| function_name | Name of the Lambda function | `string` | n/a | yes |
| runtime | Runtime for the Lambda function | `string` | `"python3.11"` | no |
| handler | Entry point for the Lambda function | `string` | `"app.lambda_handler"` | no |
| timeout | Timeout for the Lambda function in seconds | `number` | `300` | no |
| memory_size | Memory size for the Lambda function in MB | `number` | `1024` | no |
| vpc_config | VPC configuration for the Lambda function | `object` | `null` | no |
| environment_variables | Environment variables for the Lambda function | `map(string)` | `{}` | no |
| enable_dlq | Enable dead letter queue | `bool` | `true` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_name | Name of the Lambda function |
| function_arn | ARN of the Lambda function |
| function_invoke_arn | Invoke ARN of the Lambda function |
| role_arn | ARN of the Lambda execution role |
| dlq_arn | ARN of the dead letter queue |
