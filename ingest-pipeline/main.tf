terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "pipeline_name" {
  description = "Name of the OpenSearch Ingestion pipeline"
  type        = string
  default     = "nequi-kb-ingest-pipeline"
}

variable "s3_bucket_name" {
  description = "S3 bucket name containing the source data"
  type        = string
  default     = "knowledge-base-aoss-289269610742"
}

variable "opensearch_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  type        = string
  default     = "https://ws4l1vy1s2snx4ajz8oe.us-east-1.aoss.amazonaws.com"
}

variable "network_policy_name" {
  description = "Network policy name for the AOSS collection"
  type        = string
  default     = "nequi-kb-collection-net"
}

variable "index_name" {
  description = "Index name in OpenSearch"
  type        = string
  default     = "cda-docs"
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
  default     = "nequi-kb-collection"
}

variable "scan_start_time" {
  description = "Start time for S3 scan (ISO 8601 format)"
  type        = string
  default     = "2025-06-01T00:00:00"
}

variable "scan_end_time" {
  description = "End time for S3 scan (ISO 8601 format)"
  type        = string
  default     = "2025-06-08T23:59:59"
}

variable "vpc_id" {
  description = "VPC ID for OpenSearch Ingestion Service (if using VPC endpoint)"
  type        = string
  default     = "vpc-bd8716c0"
}

variable "subnet_ids" {
  description = "List of subnet IDs for OpenSearch Ingestion Service (if using VPC endpoint)"
  type        = list(string)
  default     = ["subnet-75bda838"]
}

variable "log_group_name" {
  description = "CloudWatch log group name for OpenSearch Ingestion Service logs"
  type        = string
  default     = "/aws/vendedlogs/OpenSearchIngestion/ingest-data/audit-logs"
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM role for OpenSearch Ingestion Service
resource "aws_iam_role" "osis_role" {
  name = "OpenSearchIngestion-${var.pipeline_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "osis-pipelines.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.pipeline_name}-role"
    Environment = "development"
    Purpose     = "osis-ingestion"
  }
}

# IAM policy for S3 access
resource "aws_iam_policy" "osis_s3_policy" {
  name        = "OSIS_S3ScanSource_${var.pipeline_name}"
  description = "Policy for OSIS to access S3 bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "allowReadingFromS3Buckets",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        "Sid" : "allowListAllMyBuckets",
        "Effect" : "Allow",
        "Action" : "s3:ListAllMyBuckets",
        "Resource" : "arn:aws:s3:::*"
      }
    ]
  })
}

# IAM policy for OpenSearch Serverless access
resource "aws_iam_policy" "osis_aoss_policy" {
  name        = "OSIS_OpenSearchServerless_${var.pipeline_name}"
  description = "Policy for OSIS to access OpenSearch Serverless"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "allowAPIs",
        "Effect" : "Allow",
        "Action" : [
          "aoss:APIAccessAll",
          "aoss:BatchGetCollection",
          "aoss:GetSecurityPolicy"
        ],
        "Resource" : [
          "arn:aws:aoss:*:${data.aws_caller_identity.current.account_id}:collection/*"
        ]
      },
      {
        "Sid" : "AccessDashboard",
        "Effect" : "Allow",
        "Action" : [
          "aoss:DashboardsAccessAll"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "allowSecurityPolicy",
        "Effect" : "Allow",
        "Action" : [
          "aoss:CreateSecurityPolicy",
          "aoss:UpdateSecurityPolicy",
          "aoss:GetSecurityPolicy"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aoss:collection" : [
              "${var.collection_name}",
            ]
          },
          "StringEquals" : {
            "aws:ResourceAccount" : [
              "${data.aws_caller_identity.current.account_id}"
            ]
          }
        }
      }
    ]
  })
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "osis_s3_attachment" {
  role       = aws_iam_role.osis_role.name
  policy_arn = aws_iam_policy.osis_s3_policy.arn
}

# Attach AOSS policy to role
resource "aws_iam_role_policy_attachment" "osis_aoss_attachment" {
  role       = aws_iam_role.osis_role.name
  policy_arn = aws_iam_policy.osis_aoss_policy.arn
}

# OpenSearch Ingestion Pipeline
resource "aws_opensearchserverless_vpc_endpoint" "osis_endpoint" {
  count      = 0 # Set to 1 if you need VPC endpoint
  name       = "${var.pipeline_name}-vpc-endpoint"
  vpc_id     = var.vpc_id     # Specify your VPC ID if using VPC endpoint
  subnet_ids = var.subnet_ids # Specify your subnet IDs if using VPC endpoint
}

# OpenSearch Ingestion Pipeline
resource "aws_osis_pipeline" "ingestion_pipeline" {
  pipeline_name = var.pipeline_name

  log_publishing_options {
    is_logging_enabled = true
    cloudwatch_log_destination {
      log_group = var.log_group_name
    }
  }

  pipeline_configuration_body = yamlencode({
    version = "2"
    extension = {
      osis_configuration_metadata = {
        builder_type = "visual"
      }
    }
    "${var.pipeline_name}" = {
      source = {
        s3 = {
          acknowledgments = true
          scan = {
            buckets = [
              {
                bucket = {
                  name       = var.s3_bucket_name
                  start_time = var.scan_start_time
                  end_time   = var.scan_end_time
                }
              }
            ]
            start_time = var.scan_start_time
            end_time   = var.scan_end_time
          }
          aws = {
            region       = var.aws_region
            sts_role_arn = aws_iam_role.osis_role.arn
          }
          codec = {
            ndjson = {}
          }
          compression = "none"
          workers     = "1"
        }
      }
      processor = [
        {
          parse_json = {
            source               = "results"
            handle_failed_events = "skip"
          }
        }
      ]
      sink = [
        {
          opensearch = {
            hosts = [var.opensearch_endpoint]
            aws = {
              serverless   = true
              region       = var.aws_region
              sts_role_arn = aws_iam_role.osis_role.arn
              serverless_options = {
                network_policy_name = var.network_policy_name
              }
            }
            index_type = "custom"
            index      = var.index_name
          }
        }
      ]
    }
  })

  min_units = 1
  max_units = 4

  tags = {
    Name        = var.pipeline_name
    Environment = "development"
    Purpose     = "knowledge-base-ingestion"
  }

  depends_on = [
    aws_iam_role_policy_attachment.osis_s3_attachment,
    aws_iam_role_policy_attachment.osis_aoss_attachment
  ]
}

# Outputs
output "pipeline_arn" {
  description = "ARN of the OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.ingestion_pipeline.pipeline_arn
}

output "pipeline_endpoint" {
  description = "Endpoint of the OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.ingestion_pipeline.ingest_endpoint_urls
}

output "osis_role_arn" {
  description = "ARN of the OSIS IAM role"
  value       = aws_iam_role.osis_role.arn
}

# output "pipeline_status" {
#   description = "Status of the pipeline"
#   value       = aws_osis_pipeline.ingestion_pipeline.status
# }