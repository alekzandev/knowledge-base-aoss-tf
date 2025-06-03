# Simple AOSS Collection Example

This example demonstrates how to create a basic Amazon OpenSearch Serverless (AOSS) collection using the `aoss-collection` module with public access for development and testing.

## What This Example Creates

- ✅ OpenSearch Serverless collection optimized for vector search
- ✅ Data access policy with specific IAM principals
- ✅ Network policy allowing public access
- ✅ Encryption policy using AWS-owned KMS keys
- ✅ Optional ingestion role for data pipelines

## Usage

1. **Navigate to this directory:**
   ```bash
   cd examples/aoss-simple
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the plan:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

5. **Get the outputs:**
   ```bash
   terraform output
   ```

## Configuration

The example uses the following defaults:
- **Region:** `us-east-1`
- **Collection Name:** `nequi-kb-collection`
- **Environment:** `development`
- **Collection Type:** `VECTORSEARCH`
- **Access:** Public access enabled
- **Encryption:** AWS-owned KMS keys

## Customization

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
aws_region      = "us-west-2"
collection_name = "my-custom-collection"
environment     = "staging"
```

## Expected Outputs

After successful deployment, you'll see:

```
collection_arn = "arn:aws:aoss:us-east-1:289269610742:collection/abcdef123456"
collection_endpoint = "https://abcdef123456.us-east-1.aoss.amazonaws.com"
collection_id = "abcdef123456"
collection_name = "nequi-kb-collection"
dashboard_endpoint = "https://abcdef123456.us-east-1.aoss.amazonaws.com/_dashboards"
```

## Testing the Collection

Once deployed, you can test the collection:

1. **Basic connectivity test:**
   ```bash
   curl -X GET "$(terraform output -raw collection_endpoint)/"
   ```

2. **Create a vector index (using Python):**
   ```python
   import boto3
   from opensearchpy import OpenSearch, RequestsHttpConnection
   from aws_requests_auth.aws_auth import AWSRequestsAuth

   # Get the endpoint
   endpoint = "your-collection-endpoint"
   
   # Create client
   host = endpoint.replace('https://', '')
   region = 'us-east-1'
   service = 'aoss'
   credentials = boto3.Session().get_credentials()
   awsauth = AWSRequestsAuth(credentials, region, service)

   client = OpenSearch(
       hosts=[{'host': host, 'port': 443}],
       http_auth=awsauth,
       use_ssl=True,
       verify_certs=True,
       connection_class=RequestsHttpConnection
   )

   # Create vector index
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
                   "dimension": 1536,
                   "method": {
                       "name": "hnsw",
                       "space_type": "cosinesimilarity",
                       "engine": "nmslib"
                   }
               },
               "text": {"type": "text"},
               "title": {"type": "text"},
               "url": {"type": "keyword"},
               "metadata": {"type": "object"}
           }
       }
   }

   client.indices.create(index="nequi-articles", body=index_body)
   ```

## Cost Considerations

- AOSS charges based on:
  - **Indexing compute units (ICUs):** For data ingestion
  - **Search compute units (SCUs):** For query processing
  - **Storage:** For data stored

- This simple example typically costs:
  - **Minimum:** ~$24/month (0.5 ICU + 0.5 SCU)
  - **With data:** Variable based on usage

## Cleanup

To avoid ongoing charges, destroy the resources when done:

```bash
terraform destroy
```

## Next Steps

1. **Integrate with your application:** Use the collection endpoint in your AI/ML applications
2. **Add vector data:** Start indexing your Nequi knowledge base articles
3. **Implement search:** Build vector similarity search functionality
4. **Scale up:** Consider the advanced example for production use cases

## Troubleshooting

### Common Issues

1. **Access Denied:** Verify your AWS credentials have the necessary permissions
2. **Policy Conflicts:** Ensure the collection name is unique in your account
3. **Region Issues:** Make sure you're deploying in the correct AWS region

### Verify Deployment

```bash
# Check if collection exists
aws opensearchserverless list-collections --region us-east-1

# Get collection details
aws opensearchserverless get-collection --id $(terraform output -raw collection_id) --region us-east-1
```