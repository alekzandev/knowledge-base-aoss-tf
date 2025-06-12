# OpenSearch Ingestion Pipeline Module

This Terraform module creates an AWS OpenSearch Ingestion Service (OSIS) pipeline that ingests data from S3 and loads it into an OpenSearch Serverless collection.

## Features

- **S3 to OpenSearch Ingestion**: Automatically ingests NDJSON data from S3 buckets
- **Configurable Processing**: JSON parsing with error handling
- **IAM Security**: Least-privilege IAM roles and policies
- **CloudWatch Logging**: Optional logging for monitoring and debugging
- **VPC Support**: Optional VPC endpoint for private connectivity
- **Flexible Configuration**: Customizable scan times, compression, and workers
- **Auto-scaling**: Configurable min/max units for performance scaling

## Usage

### Basic Example

```hcl
module "osis_pipeline" {
  source = "./modules/osis-pipeline"

  pipeline_name         = "my-ingestion-pipeline"
  s3_bucket_name       = "my-data-bucket"
  opensearch_endpoint  = "https://example.us-east-1.aoss.amazonaws.com"
  network_policy_name  = "my-network-policy"
  index_name           = "documents"
  collection_name      = "my-collection"

  tags = {
    Environment = "production"
    Project     = "knowledge-base"
  }
}
```

### Advanced Example with Time Filtering

```hcl
module "osis_pipeline" {
  source = "./modules/osis-pipeline"

  pipeline_name         = "filtered-ingestion-pipeline"
  s3_bucket_name       = "my-data-bucket"
  opensearch_endpoint  = "https://example.us-east-1.aoss.amazonaws.com"
  network_policy_name  = "my-network-policy"
  index_name           = "filtered-documents"
  collection_name      = "my-collection"

  # Time-based filtering
  scan_start_time      = "2025-01-01T00:00:00"
  scan_end_time        = "2025-12-31T23:59:59"

  # Performance tuning
  min_units            = 2
  max_units            = 8
  workers_count        = 3
  compression_type     = "gzip"

  # Logging
  enable_logging       = true
  log_group_name       = "/aws/osis/my-pipeline"

  tags = {
    Environment = "production"
    Project     = "knowledge-base"
  }
}
```

### VPC Endpoint Example

```hcl
module "osis_pipeline" {
  source = "./modules/osis-pipeline"

  pipeline_name         = "vpc-ingestion-pipeline"
  s3_bucket_name       = "my-private-bucket"
  opensearch_endpoint  = "https://example.us-east-1.aoss.amazonaws.com"
  network_policy_name  = "my-network-policy"
  index_name           = "private-documents"
  collection_name      = "my-private-collection"

  # VPC configuration
  enable_vpc_endpoint  = true
  vpc_id              = "vpc-12345678"
  subnet_ids          = ["subnet-12345678", "subnet-87654321"]

  tags = {
    Environment = "production"
    Project     = "knowledge-base"
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
| [aws_cloudwatch_log_group.osis_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.osis_aoss_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.osis_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.osis_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.osis_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.osis_aoss_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.osis_logs_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.osis_s3_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_opensearchserverless_vpc_endpoint.osis_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/opensearchserverless_vpc_endpoint) | resource |
| [aws_osis_pipeline.ingestion_pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/osis_pipeline) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| collection_name | Name of the OpenSearch Serverless collection | `string` | n/a | yes |
| index_name | Index name in OpenSearch where documents will be stored | `string` | n/a | yes |
| network_policy_name | Network policy name for the AOSS collection | `string` | n/a | yes |
| opensearch_endpoint | OpenSearch Serverless collection endpoint URL | `string` | n/a | yes |
| pipeline_name | Name of the OpenSearch Ingestion pipeline | `string` | n/a | yes |
| s3_bucket_name | S3 bucket name containing the source data | `string` | n/a | yes |
| compression_type | Compression type for S3 objects (none, gzip, auto) | `string` | `"none"` | no |
| enable_logging | Whether to enable CloudWatch logging for the pipeline | `bool` | `true` | no |
| enable_vpc_endpoint | Whether to create a VPC endpoint for OpenSearch Ingestion Service | `bool` | `false` | no |
| log_group_name | CloudWatch log group name for OpenSearch Ingestion Service logs | `string` | `null` | no |
| max_units | Maximum number of OpenSearch Ingestion Service units | `number` | `4` | no |
| min_units | Minimum number of OpenSearch Ingestion Service units | `number` | `1` | no |
| scan_end_time | End time for S3 scan in ISO 8601 format (e.g., 2025-07-31T23:59:59) | `string` | `null` | no |
| scan_start_time | Start time for S3 scan in ISO 8601 format (e.g., 2025-06-01T00:00:00) | `string` | `null` | no |
| subnet_ids | List of subnet IDs for OpenSearch Ingestion Service (required if enable_vpc_endpoint is true) | `list(string)` | `[]` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |
| vpc_id | VPC ID for OpenSearch Ingestion Service (required if enable_vpc_endpoint is true) | `string` | `null` | no |
| workers_count | Number of worker threads for S3 processing | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| log_group_name | Name of the CloudWatch log group (if logging is enabled) |
| osis_role_arn | ARN of the IAM role used by the OpenSearch Ingestion Service |
| osis_role_name | Name of the IAM role used by the OpenSearch Ingestion Service |
| pipeline_arn | ARN of the OpenSearch Ingestion pipeline |
| pipeline_endpoint | Endpoint URLs of the OpenSearch Ingestion pipeline |
| pipeline_name | Name of the OpenSearch Ingestion pipeline |
| pipeline_status | Status of the OpenSearch Ingestion pipeline |
| vpc_endpoint_id | ID of the VPC endpoint (if created) |

## Pipeline Configuration

The module creates an OpenSearch Ingestion pipeline with the following configuration:

### Source Configuration
- **Type**: S3
- **Format**: NDJSON
- **Acknowledgments**: Enabled for reliable processing
- **Compression**: Configurable (none, gzip, auto)
- **Workers**: Configurable (1-10)

### Processing Configuration
- **JSON Parsing**: Parses the "results" field from NDJSON
- **Error Handling**: Skips failed events to prevent pipeline failure

### Sink Configuration
- **Type**: OpenSearch Serverless
- **Index Type**: Custom
- **Authentication**: IAM-based with STS role assumption

## IAM Permissions

The module creates the following IAM resources:

### S3 Access Policy
- `s3:GetObject` - Read objects from the source bucket
- `s3:GetBucketLocation` - Get bucket location information
- `s3:ListBucket` - List objects in the bucket
- `s3:ListAllMyBuckets` - List all buckets (required by OSIS)

### OpenSearch Serverless Access Policy
- `aoss:APIAccessAll` - Full API access to AOSS collections
- `aoss:BatchGetCollection` - Batch get collection information
- `aoss:GetSecurityPolicy` - Read security policies
- `aoss:DashboardsAccessAll` - Access to OpenSearch Dashboards
- `aoss:CreateSecurityPolicy` - Create security policies (conditional)
- `aoss:UpdateSecurityPolicy` - Update security policies (conditional)

### CloudWatch Logs Access Policy (when logging enabled)
- `logs:CreateLogGroup` - Create log groups
- `logs:CreateLogStream` - Create log streams
- `logs:PutLogEvents` - Write log events
- `logs:DescribeLogGroups` - Describe log groups
- `logs:DescribeLogStreams` - Describe log streams

## Monitoring and Logging

When `enable_logging` is set to `true`, the module:
- Creates a CloudWatch log group with 30-day retention
- Configures the pipeline to send logs to CloudWatch
- Creates appropriate IAM permissions for log access

## VPC Endpoint Support

When `enable_vpc_endpoint` is set to `true`:
- A VPC endpoint is created for private connectivity
- `vpc_id` and `subnet_ids` must be provided
- The pipeline can access OpenSearch Serverless privately

## Time-based Filtering

You can filter S3 objects by modification time:
- `scan_start_time`: Only process objects modified after this time
- `scan_end_time`: Only process objects modified before this time
- Times must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SS)

## Performance Tuning

- **Units**: Configure `min_units` and `max_units` for auto-scaling
- **Workers**: Increase `workers_count` for better S3 processing throughput
- **Compression**: Use `gzip` compression for better network efficiency

## Error Handling

The pipeline is configured to skip failed events during JSON parsing, ensuring that malformed documents don't stop the entire ingestion process.

## Tags

All resources created by this module are tagged with:
- `Name`: The pipeline name
- `Module`: "osis-pipeline"
- `ManagedBy`: "terraform"
- Additional custom tags from the `tags` variable

## Notes

- The S3 bucket and OpenSearch Serverless collection must exist before creating the pipeline
- Network policies for the OpenSearch collection must be configured separately
- The module supports NDJSON format only
- Pipeline processing starts automatically after creation
