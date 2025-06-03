# Amazon OpenSearch Serverless (AOSS) Collection Module

This Terraform module creates an Amazon OpenSearch Serverless collection with proper security policies for vector search operations, specifically optimized for AI/ML knowledge base applications.

## Features

- ✅ **Vector Search Optimized**: Designed for VECTORSEARCH collection type
- ✅ **Flexible Access Control**: Support for multiple principals and ingestion roles
- ✅ **Public/Private Access**: Configurable network access policies
- ✅ **Encryption Options**: Support for AWS-owned or customer-managed KMS keys
- ✅ **Production Ready**: Based on working configuration with proper dependencies
- ✅ **Comprehensive Outputs**: All necessary endpoints and ARNs for integration

## Usage

### Basic Example (Vector Search with Public Access)

```hcl
module "nequi_kb_collection" {
  source = "./modules/aoss-collection"

  collection_name = "nequi-kb-collection"
  environment     = "production"
  purpose         = "knowledge-base"

  # Grant access to specific IAM users/roles
  principals = [
    "arn:aws:iam::289269610742:user/hausdorff94_main",
    "arn:aws:iam::289269610742:user/hausdorff94"
  ]

  # Optional: Add ingestion role for data pipelines
  ingestion_role_arn = "arn:aws:iam::289269610742:role/service-role/OpenSearchIngestion-role"

  # Security settings
  allow_public_access = true
  collection_type     = "VECTORSEARCH"
  encryption_key_type = "AWS_OWNED_KMS_KEY"

  tags = {
    Project     = "nequi-chatbot"
    Team        = "ai-ml"
    CostCenter  = "engineering"
  }
}
```

### Advanced Example (Private Access with Customer-Managed KMS)

```hcl
module "secure_collection" {
  source = "./modules/aoss-collection"

  collection_name = "secure-vectors"
  environment     = "production"
  purpose         = "sensitive-data"

  principals = [
    "arn:aws:iam::289269610742:role/lambda-execution-role",
    "arn:aws:iam::289269610742:role/data-scientist-role"
  ]

  # Private access only
  allow_public_access = false
  collection_type     = "VECTORSEARCH"
  
  # Customer-managed encryption
  encryption_key_type = "CUSTOMER_MANAGED_KMS_KEY"
  kms_key_id         = "arn:aws:kms:us-east-1:289269610742:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
    Compliance  = "SOC2"
    DataClass   = "confidential"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_opensearchserverless_access_policy.data_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearchserverless_access_policy) | resource |
| [aws_opensearchserverless_collection.kb_collection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearchserverless_collection) | resource |
| [aws_opensearchserverless_security_policy.encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearchserverless_security_policy) | resource |
| [aws_opensearchserverless_security_policy.network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearchserverless_security_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| collection\_name | Name of the OpenSearch Serverless collection | `string` | n/a | yes |
| allow\_public\_access | Whether to allow public access to the collection | `bool` | `true` | no |
| collection\_type | Type of the collection (SEARCH, TIMESERIES, or VECTORSEARCH) | `string` | `"VECTORSEARCH"` | no |
| encryption\_key\_type | Encryption key type (AWS\_OWNED\_KMS\_KEY or CUSTOMER\_MANAGED\_KMS\_KEY) | `string` | `"AWS_OWNED_KMS_KEY"` | no |
| environment | Environment name | `string` | `"development"` | no |
| ingestion\_role\_arn | ARN of the OpenSearch Ingestion role (optional) | `string` | `""` | no |
| kms\_key\_id | KMS key ID for customer-managed encryption | `string` | `""` | no |
| principals | List of principals (IAM roles/users) to grant access to the collection | `list(string)` | `[]` | no |
| purpose | Purpose of the collection | `string` | `"knowledge-base"` | no |
| tags | Additional tags for the collection | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| collection\_arn | OpenSearch Serverless collection ARN |
| collection\_endpoint | OpenSearch Serverless collection endpoint |
| collection\_id | OpenSearch Serverless collection ID |
| collection\_name | OpenSearch Serverless collection name |
| dashboard\_endpoint | OpenSearch Dashboards endpoint |
| data\_access\_policy\_arn | ARN of the data access policy |
| data\_access\_policy\_name | Name of the data access policy |
| encryption\_policy\_arn | ARN of the encryption security policy |
| encryption\_policy\_name | Name of the encryption security policy |
| network\_policy\_arn | ARN of the network security policy |
| network\_policy\_name | Name of the network security policy |

## Integration Examples

### With Lambda Function

```hcl
# Create the collection
module "kb_collection" {
  source = "./modules/aoss-collection"
  
  collection_name = "ai-vectors"
  principals = [
    aws_iam_role.lambda_role.arn
  ]
}

# Use in Lambda environment variables
resource "aws_lambda_function" "ai_function" {
  # ... other configuration ...
  
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = module.kb_collection.collection_endpoint
      COLLECTION_NAME     = module.kb_collection.collection_name
    }
  }
}
```

### Vector Index Creation

After the collection is created, you can create a vector index:

```python
import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth

# Create index with vector field
index_body = {
    "settings": {
        "index": {
            "knn": True,
            "knn.algo_param.ef_search": 100
        }
    },
    "mappings": {
        "properties": {
            "vector_field": {
                "type": "knn_vector",
                "dimension": 1536,  # For OpenAI embeddings
                "method": {
                    "name": "hnsw",
                    "space_type": "cosinesimilarity",
                    "engine": "nmslib"
                }
            },
            "text": {"type": "text"},
            "metadata": {"type": "object"}
        }
    }
}
```

## Security Considerations

1. **Production Use**: For production environments, consider setting `allow_public_access = false`
2. **Encryption**: Use customer-managed KMS keys for sensitive data
3. **Least Privilege**: Only grant necessary permissions to specific principals
4. **Network Security**: Consider using VPC endpoints for private access

## Best Practices

1. **Naming Convention**: Use descriptive collection names with environment suffixes
2. **Tagging**: Always include environment, project, and cost center tags
3. **Access Control**: Use specific IAM roles rather than broad permissions
4. **Monitoring**: Enable CloudWatch logging and metrics for the collection

## Troubleshooting

### Common Issues

1. **Collection Creation Fails**: Ensure all policies are created before the collection
2. **Access Denied**: Verify the principals are correctly formatted ARNs
3. **KMS Errors**: Ensure the KMS key exists and has proper permissions when using customer-managed keys

### Validation

After deployment, verify the collection is working:

```bash
# Get collection endpoint
terraform output collection_endpoint

# Test basic connectivity (replace with your endpoint)
curl -X GET "https://your-collection-endpoint.us-east-1.aoss.amazonaws.com/"
```

## License

This module is released under the MIT License.