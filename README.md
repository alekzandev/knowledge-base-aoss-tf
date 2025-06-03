# AI Chatbot Infrastructure - Terraform Modules

This repository contains production-grade Terraform modules for AWS services optimized for AI chatbot solutions using OpenSearch Serverless vector databases and generative AI services.

## Architecture Overview

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
                       └──────────────────┘              │
                              │                          │
                              ▼                          │
                       ┌──────────────────┐              │
                       │   Amazon S3      │◀─────────────┘
                       │ (Optional Backup)│
                       └──────────────────┘
```

## Modules

### OpenSearch Serverless Module (`modules/opensearch-vector-db`) ⭐ **Primary**

- **Production-ready vector database** for near real-time similarity search
- k-NN search with configurable similarity metrics (cosine, euclidean, dot product)
- Serverless auto-scaling with cost optimization
- Built-in security policies and VPC endpoint support
- CloudWatch monitoring and alerting
- Index template management for vector fields

### Lambda AI Execution Module (`modules/lambda-ai-execution`)

- **Serverless AI model execution** environment optimized for OpenSearch integration
- Auto-scaling configuration with provisioned concurrency
- Integrated with Amazon Bedrock for embeddings and text generation
- VPC and security group integration for private network access
- Dead letter queue and X-Ray tracing support
- Performance monitoring and CloudWatch insights

### S3 Vector Storage Module (`modules/s3-vector-storage`) 🔄 **Optional Backup**

- **Optional backup storage** for interaction logging and data persistence
- Intelligent storage tiering for cost optimization
- Cross-region replication support for disaster recovery
- KMS encryption and comprehensive security features
- Lifecycle management for automated data archival

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd kb-llm
   ```

2. **Navigate to examples**:
   ```bash
   cd examples
   ```

3. **Configure your deployment**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

4. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan -var-file="terraform.tfvars"
   terraform apply -var-file="terraform.tfvars"
   ```

## Key Features

- **OpenSearch-First Architecture**: Optimized for near real-time vector search
- **Serverless Scaling**: Auto-scaling OpenSearch and Lambda for cost efficiency
- **AI Model Integration**: Seamless Amazon Bedrock integration
- **Production Ready**: Comprehensive monitoring, security, and error handling
- **Modular Design**: Use individual modules or complete solution
- **Cost Optimized**: Intelligent tiering and serverless architecture

## Requirements

- Terraform >= 1.5
- AWS Provider >= 5.0
- Appropriate AWS credentials and permissions
- Amazon Bedrock model access (Titan Embeddings, Claude/other text models)
