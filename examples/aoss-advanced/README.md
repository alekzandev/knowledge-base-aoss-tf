# Advanced AOSS Collection Example

This example demonstrates a production-ready Amazon OpenSearch Serverless (AOSS) collection with comprehensive security, monitoring, and integration features.

## Features

- ✅ **Production Security**: Private access, customer-managed KMS encryption
- ✅ **IAM Integration**: Lambda execution role and custom principals
- ✅ **Monitoring**: CloudWatch logs, metrics, and alarms
- ✅ **Alerting**: SNS notifications for operational issues
- ✅ **Best Practices**: Proper tagging, naming conventions, and security

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Lambda        │    │   OpenSearch     │    │   CloudWatch    │
│   Function      │───▶│   Serverless     │───▶│   Logs/Metrics  │
│                 │    │   Collection     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       ▼
         ▼                       ▼              ┌─────────────────┐
┌─────────────────┐    ┌──────────────────┐    │   SNS Alerts    │
│   IAM Roles     │    │   KMS Key        │    │   & Email       │
│   & Policies    │    │   (Customer)     │    │   Notifications │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## What This Example Creates

### Core Resources
- OpenSearch Serverless collection (VECTORSEARCH)
- Data access, network, and encryption policies
- Customer-managed KMS key with rotation

### Security & IAM
- Lambda execution role with OpenSearch permissions
- Custom IAM principals for user/role access
- Private network access (no public access)

### Monitoring & Alerting
- CloudWatch log group for collection logs
- CloudWatch alarms for search latency
- SNS topic and email subscriptions for alerts

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update the configuration:**
   Edit `terraform.tfvars` with your specific values:
   - AWS account ID in IAM ARNs
   - Email address for alerts
   - Environment-specific settings

3. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration Options

### Security Levels

**Development/Testing:**
```hcl
allow_public_access      = true
use_customer_managed_kms = false
enable_alerting         = false
```

**Production:**
```hcl
allow_public_access      = false
use_customer_managed_kms = true
enable_alerting         = true
```

### Principal Configuration

Update the `additional_principals` variable with your IAM users/roles:

```hcl
additional_principals = [
  "arn:aws:iam::YOUR-ACCOUNT:user/your-username",
  "arn:aws:iam::YOUR-ACCOUNT:role/your-application-role",
  "arn:aws:iam::YOUR-ACCOUNT:role/data-scientist-role"
]
```

### Monitoring Thresholds

Adjust monitoring thresholds based on your requirements:

```hcl
search_latency_threshold = 500    # milliseconds
log_retention_days      = 90     # days
alert_email            = "ops@yourcompany.com"
```

## Integration Examples

### Lambda Function Integration

```python
import boto3
import json
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth

def lambda_handler(event, context):
    # Use the Lambda role created by this example
    endpoint = "your-collection-endpoint"
    region = "us-east-1"
    
    # Authentication using the Lambda execution role
    credentials = boto3.Session().get_credentials()
    awsauth = AWSRequestsAuth(credentials, region, 'aoss')
    
    client = OpenSearch(
        hosts=[{'host': endpoint.replace('https://', ''), 'port': 443}],
        http_auth=awsauth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection
    )
    
    # Perform vector search
    search_body = {
        "query": {
            "knn": {
                "vector_field": {
                    "vector": event.get("query_vector"),
                    "k": 10
                }
            }
        }
    }
    
    response = client.search(
        index="nequi-articles",
        body=search_body
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }
```

### Data Ingestion with Boto3

```python
import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth

# Setup client
endpoint = "your-collection-endpoint"
region = "us-east-1"
credentials = boto3.Session().get_credentials()
awsauth = AWSRequestsAuth(credentials, region, 'aoss')

client = OpenSearch(
    hosts=[{'host': endpoint.replace('https://', ''), 'port': 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

# Index a document
document = {
    "title": "Nequi Payment Methods",
    "text": "Nequi supports multiple payment methods...",
    "vector_field": [0.1, 0.2, 0.3, ...],  # 1536-dimensional vector
    "metadata": {
        "category": "payments",
        "language": "es",
        "last_updated": "2025-06-02"
    }
}

response = client.index(
    index="nequi-articles",
    body=document,
    id="article-123"
)
```

## Monitoring and Alerts

### CloudWatch Metrics

The example automatically monitors:
- **Search Latency**: Average response time for search requests
- **Search Request Count**: Number of search operations
- **Indexing Request Count**: Number of indexing operations

### Alert Conditions

Alerts are triggered when:
- Search latency exceeds the configured threshold (default: 1000ms)
- Collection becomes unavailable
- Error rates spike above normal levels

### Log Analysis

View logs in CloudWatch:
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/opensearch/collections/"
aws logs get-log-events --log-group-name "/aws/opensearch/collections/your-collection-name"
```

## Cost Optimization

### Compute Units
- **ICU (Indexing)**: 0.5 minimum, scale based on ingestion volume
- **SCU (Search)**: 0.5 minimum, scale based on query volume

### Storage
- Charged per GB stored
- Use lifecycle policies for archival if needed

### Estimated Costs
- **Minimum (empty collection)**: ~$24/month
- **With 10GB data + moderate usage**: ~$50-100/month
- **Production workload**: Variable based on usage patterns

## Security Best Practices

1. **Network Security**
   - Use private access for production
   - Implement VPC endpoints if needed
   - Regular security reviews

2. **Encryption**
   - Customer-managed KMS keys for sensitive data
   - Enable key rotation
   - Regular key audits

3. **Access Control**
   - Principle of least privilege
   - Regular principal reviews
   - Use roles instead of users when possible

4. **Monitoring**
   - Enable comprehensive logging
   - Set up proactive alerts
   - Regular security monitoring

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   ```bash
   # Check principal ARNs
   aws sts get-caller-identity
   
   # Verify data access policy
   aws opensearchserverless get-access-policy --name your-collection-data-access --type data
   ```

2. **High Latency Alerts**
   ```bash
   # Check collection metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/AOSS \
     --metric-name SearchLatency \
     --dimensions Name=CollectionName,Value=your-collection-name \
     --start-time 2025-06-02T00:00:00Z \
     --end-time 2025-06-02T23:59:59Z \
     --period 3600 \
     --statistics Average
   ```

3. **KMS Key Issues**
   ```bash
   # Check key status
   aws kms describe-key --key-id your-key-id
   
   # Verify key permissions
   aws kms get-key-policy --key-id your-key-id --policy-name default
   ```

### Validation Commands

```bash
# Verify collection status
terraform output collection_endpoint
terraform output collection_arn

# Test connectivity
curl -X GET "$(terraform output -raw collection_endpoint)/"

# Check policies
aws opensearchserverless list-access-policies --type data
aws opensearchserverless list-security-policies --type network
aws opensearchserverless list-security-policies --type encryption
```

## Cleanup

To avoid ongoing charges:

```bash
# Destroy all resources
terraform destroy

# Verify cleanup
aws opensearchserverless list-collections
aws kms list-keys --query 'Keys[?KeyId==`your-key-id`]'
```

## Next Steps

1. **Vector Index Setup**: Create optimized indices for your use case
2. **Data Pipeline**: Implement automated data ingestion
3. **Application Integration**: Connect your AI/ML applications
4. **Performance Tuning**: Optimize based on usage patterns
5. **Security Hardening**: Implement additional security controls
