# OpenSearch Serverless Vector Database Module

A production-ready Terraform module for creating and managing AWS OpenSearch Serverless collections optimized for vector similarity search in AI chatbot applications.

## Features

- **Vector Search Optimized**: Purpose-built for near real-time vector similarity search with configurable dimensions and similarity metrics
- **Serverless Architecture**: Auto-scaling OpenSearch Serverless collection with pay-per-use pricing
- **Security Best Practices**: Comprehensive security policies, encryption, and access controls
- **Monitoring & Observability**: Built-in CloudWatch dashboards, alarms, and logging
- **VPC Integration**: Optional VPC endpoints for private access
- **IAM Integration**: Pre-configured IAM roles and policies for Lambda functions
- **Production Ready**: Configurable performance settings, auto-scaling, and error handling

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    OpenSearch Serverless                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Collection    │  │   Index with    │  │   Vector        │ │
│  │   (Serverless)  │  │   Vector Field  │  │   Embeddings    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Security      │  │   Network       │  │   Data Access   │ │
│  │   Policies      │  │   Policies      │  │   Policies      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   CloudWatch    │  │   VPC Endpoint  │  │   IAM Roles     │ │
│  │   Monitoring    │  │   (Optional)    │  │   & Policies    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

| Metric | Range | Typical Use Case |
|--------|-------|------------------|
| Search Latency | 10-100ms | Near real-time similarity search |
| Indexing Latency | 50-200ms | Document ingestion |
| Throughput | 1K-10K QPS | High-volume applications |
| Vector Dimensions | 1-10,000 | Various embedding models |

## Quick Start

### Basic Usage

```hcl
module "opensearch_vector_db" {
  source = "./modules/opensearch-vector-db"

  collection_name = "ai-chatbot-vectors"
  environment     = "prod"
  
  # Vector configuration
  vector_dimension       = 1536  # OpenAI embeddings
  vector_similarity_metric = "cosine"
  
  # Security
  principal_arns = [
    aws_iam_role.lambda_execution_role.arn
  ]
  
  # Monitoring
  enable_logging  = true
  enable_alarms   = true
  create_dashboard = true
  
  common_tags = {
    Project     = "AI-Chatbot"
    Environment = "prod"
    Team        = "AI-Engineering"
  }
}
```

### Advanced Configuration with VPC

```hcl
module "opensearch_vector_db" {
  source = "./modules/opensearch-vector-db"

  collection_name = "ai-chatbot-vectors"
  environment     = "prod"
  
  # Vector configuration
  vector_dimension       = 1536
  vector_similarity_metric = "cosine"
  vector_engine         = "nmslib"
  
  # Index configuration
  index_name         = "knowledge-base"
  number_of_shards   = 4
  number_of_replicas = 2
  refresh_interval   = "1s"
  
  # Security
  principal_arns = [
    aws_iam_role.lambda_execution_role.arn,
    aws_iam_role.data_ingestion_role.arn
  ]
  allow_public_access = false
  
  # VPC Configuration
  create_vpc_endpoint = true
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.opensearch.id]
  
  # Monitoring
  enable_logging         = true
  log_retention_days     = 30
  enable_alarms          = true
  search_latency_threshold = 500
  alarm_actions          = [aws_sns_topic.alerts.arn]
  
  # IAM
  create_lambda_role = true
  
  common_tags = {
    Project     = "AI-Chatbot"
    Environment = "prod"
    Team        = "AI-Engineering"
  }
}
```

## Vector Search Configuration

### Supported Embedding Models

| Model | Dimensions | Similarity Metric | Use Case |
|-------|------------|-------------------|----------|
| OpenAI text-embedding-ada-002 | 1536 | cosine | General text embeddings |
| OpenAI text-embedding-3-small | 1536 | cosine | Cost-effective embeddings |
| OpenAI text-embedding-3-large | 3072 | cosine | High-quality embeddings |
| Amazon Titan Text | 1536 | cosine | AWS-native embeddings |
| Cohere Embed | 4096 | cosine | Multilingual embeddings |

### Similarity Metrics

- **cosine**: Measures cosine similarity (recommended for most text embeddings)
- **l2**: Euclidean distance (good for normalized vectors)
- **inner_product**: Dot product similarity (for specific use cases)

## Outputs

The module provides comprehensive outputs for integration with other components:

```hcl
# Collection information
collection_endpoint    = "https://xyz.us-east-1.aoss.amazonaws.com"
collection_arn        = "arn:aws:aoss:us-east-1:123456789012:collection/abc123"

# Connection details
connection_info = {
  endpoint        = "https://xyz.us-east-1.aoss.amazonaws.com"
  collection_name = "ai-chatbot-vectors-prod"
  index_name      = "knowledge-base"
  region         = "us-east-1"
}

# Monitoring resources
monitoring_resources = {
  log_group_name = "/aws/opensearch/serverless/ai-chatbot-vectors-prod"
  dashboard_name = "ai-chatbot-vectors-opensearch-prod"
  alarms_enabled = true
}
```

## Integration Examples

### Lambda Function Integration

```python
import boto3
import json
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth

def lambda_handler(event, context):
    # OpenSearch client setup
    host = 'xyz.us-east-1.aoss.amazonaws.com'
    region = 'us-east-1'
    service = 'aoss'
    
    credentials = boto3.Session().get_credentials()
    awsauth = AWSRequestsAuth(credentials, region, service)
    
    client = OpenSearch(
        hosts=[{'host': host, 'port': 443}],
        http_auth=awsauth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        pool_maxsize=20,
    )
    
    # Vector search
    search_vector = event['query_vector']
    
    query = {
        "size": 10,
        "query": {
            "knn": {
                "vector_field": {
                    "vector": search_vector,
                    "k": 10
                }
            }
        },
        "_source": ["content", "metadata", "source"]
    }
    
    response = client.search(
        body=query,
        index="knowledge-base"
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(response['hits']['hits'])
    }
```

### Index Template Creation

```bash
# Create index template for vector documents
curl -XPUT "https://xyz.us-east-1.aoss.amazonaws.com/_index_template/knowledge-base-template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["knowledge-base-*"],
    "template": {
      "mappings": {
        "properties": {
          "vector_field": {
            "type": "knn_vector",
            "dimension": 1536,
            "method": {
              "name": "hnsw",
              "space_type": "cosinesimil",
              "engine": "nmslib"
            }
          },
          "content": {
            "type": "text",
            "analyzer": "standard"
          },
          "metadata": {
            "type": "object"
          },
          "timestamp": {
            "type": "date"
          },
          "source": {
            "type": "keyword"
          }
        }
      },
      "settings": {
        "index": {
          "number_of_shards": 2,
          "number_of_replicas": 1,
          "refresh_interval": "1s",
          "max_result_window": 10000
        }
      }
    }
  }'
```

## Monitoring and Alerting

The module includes comprehensive monitoring:

### CloudWatch Metrics

- **SearchLatency**: Average search request latency
- **SearchRate**: Number of search requests per second
- **SearchErrors**: Number of failed search requests
- **IndexingLatency**: Average indexing latency
- **IndexingRate**: Number of indexing requests per second
- **IndexingErrors**: Number of failed indexing requests

### Default Alarms

- High search latency (>1000ms)
- High search error rate (>5 errors)

### Custom Dashboard

Includes pre-configured CloudWatch dashboard with:
- Search performance metrics
- Indexing performance metrics
- Error rates and trends
- Capacity utilization

## Security

### Access Control

- **Encryption**: AWS-owned KMS keys by default
- **Network**: VPC endpoints for private access
- **IAM**: Fine-grained access policies
- **Data Access**: Resource-based policies

### Security Policies

1. **Encryption Policy**: Defines encryption requirements
2. **Network Policy**: Controls network access
3. **Data Access Policy**: Defines who can access what data

## Cost Optimization

### Pricing Model

OpenSearch Serverless pricing is based on:
- **OpenSearch Compute Units (OCUs)**: $0.24/hour per OCU
- **Storage**: $0.024/GB per month
- **Data Transfer**: Standard AWS data transfer rates

### Cost Optimization Tips

1. **Right-size your vectors**: Use appropriate dimensions
2. **Optimize refresh intervals**: Balance freshness vs. cost
3. **Use appropriate replica counts**: Based on availability needs
4. **Monitor capacity**: Set up auto-scaling boundaries

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Check IAM policies and principal ARNs
   - Verify data access policy configuration

2. **High Latency**
   - Review vector dimensions and similarity metrics
   - Check shard and replica configuration
   - Monitor capacity utilization

3. **Indexing Failures**
   - Verify vector dimensions match configuration
   - Check document format and mapping

### Debug Commands

```bash
# Check collection status
aws opensearchserverless list-collections

# View collection details
aws opensearchserverless batch-get-collection --ids <collection-id>

# Check policies
aws opensearchserverless list-security-policies --type encryption
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Variables

See [variables.tf](./variables.tf) for a complete list of configurable variables.

## Outputs

See [outputs.tf](./outputs.tf) for a complete list of module outputs.

## License

This module is licensed under the MIT License. See [LICENSE](../../LICENSE) for details.

## Contributing

Please read our [contributing guidelines](../../CONTRIBUTING.md) before submitting pull requests.
