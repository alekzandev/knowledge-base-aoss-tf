# S3 Vector Storage Module

This module creates an S3 bucket optimized for storing vector embeddings and related AI model artifacts.

## Features

- **Intelligent Storage Tiering**: Automatically optimizes storage costs
- **Encryption**: Server-side encryption with customer-managed KMS keys
- **Versioning**: Enabled for data protection and rollback capabilities
- **Cross-Region Replication**: Optional replication for disaster recovery
- **Lifecycle Management**: Automated transition to cost-effective storage classes
- **Access Logging**: Comprehensive audit trail
- **Public Access Block**: Security-first configuration

## Usage

```hcl
module "vector_storage" {
  source = "./modules/s3-vector-storage"
  
  project_name = "ai-chatbot"
  environment  = "prod"
  
  enable_versioning     = true
  enable_replication    = true
  replication_region    = "us-west-2"
  
  lifecycle_rules = [
    {
      id     = "vector_embeddings"
      status = "Enabled"
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]
  
  tags = {
    Project = "AI-Chatbot"
    Owner   = "Data-Science-Team"
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
| enable_versioning | Enable S3 bucket versioning | `bool` | `true` | no |
| enable_replication | Enable cross-region replication | `bool` | `false` | no |
| replication_region | Target region for replication | `string` | `null` | no |
| lifecycle_rules | List of lifecycle rules | `list(object)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | Name of the created S3 bucket |
| bucket_arn | ARN of the created S3 bucket |
| bucket_domain_name | Domain name of the S3 bucket |
| kms_key_arn | ARN of the KMS key used for encryption |
