# Example: Complete AI Chatbot Infrastructure with OpenSearch Vector Database
# This example demonstrates the usage of OpenSearch Serverless as the primary vector database
# with Lambda AI execution for near real-time similarity search and model inference

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.replication]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# Provider configuration for primary region
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# Provider configuration for replication region (if cross-region replication is enabled)
provider "aws" {
  alias  = "replication"
  region = var.replication_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      Purpose     = "replication"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    CreatedBy   = "terraform"
    Timestamp   = timestamp()
  }
}

# Primary Vector Database - OpenSearch Serverless
module "opensearch_vector_db" {
  source = "../modules/opensearch-vector-db"

  collection_name = "${var.project_name}-vectors"
  environment     = var.environment

  # Vector configuration optimized for AI chatbots
  vector_dimension         = var.vector_dimension
  vector_similarity_metric = var.vector_similarity_metric
  vector_engine            = var.vector_engine
  index_name               = var.opensearch_index_name

  # Performance configuration
  number_of_shards   = var.opensearch_shards
  number_of_replicas = var.opensearch_replicas
  refresh_interval   = "1s" # Near real-time

  # Security configuration
  # Note: Principal ARNs are managed separately to avoid circular dependency
  allow_public_access = false

  # VPC configuration (optional)
  create_vpc_endpoint = var.opensearch_create_vpc_endpoint
  vpc_id              = var.vpc_id
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.opensearch_security_group_ids

  # Monitoring and observability
  enable_logging           = true
  log_retention_days       = var.log_retention_days
  create_dashboard         = true
  enable_alarms            = true
  search_latency_threshold = 100 # 100ms for near real-time
  alarm_actions            = var.alarm_notification_arns

  # Index template configuration
  enable_index_template = true
  document_metadata_fields = [
    "source",
    "timestamp",
    "category",
    "content_type",
    "document_id",
    "chunk_index",
    "relevance_score"
  ]

  common_tags = merge(local.common_tags, {
    Component = "primary-vector-database"
    Purpose   = "real-time-similarity-search"
  })
}

# Lambda AI Execution Module with OpenSearch Integration
module "ai_lambda" {
  source = "../modules/lambda-ai-execution"

  project_name  = var.project_name
  environment   = var.environment
  function_name = "ai-model-inference"

  # Function configuration optimized for AI workloads
  runtime      = var.lambda_runtime
  handler      = var.lambda_handler
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory_size
  architecture = var.lambda_architecture

  # Source code configuration
  filename = var.lambda_source_file

  # OpenSearch integration
  opensearch_endpoint         = module.opensearch_vector_db.collection_endpoint
  opensearch_collection_name  = module.opensearch_vector_db.collection_name
  opensearch_index_name       = var.opensearch_index_name
  opensearch_vector_field     = "vector_field"
  opensearch_vector_dimension = var.vector_dimension
  enable_opensearch_access    = true

  # Vector search configuration
  vector_search_config = {
    similarity_threshold = var.similarity_threshold
    max_results          = var.max_search_results
    search_timeout       = 30
    enable_filtering     = true
  }

  # AI model configuration
  bedrock_model_config = {
    embedding_model_id = var.embedding_model_id
    text_model_id      = var.text_model_id
    max_tokens         = var.max_tokens
    temperature        = var.temperature
  }

  # Knowledge base configuration
  knowledge_base_config = {
    chunk_size                = var.chunk_size
    chunk_overlap             = var.chunk_overlap
    min_relevance_score       = var.min_relevance_score
    enable_metadata_filtering = true
    supported_content_types   = var.supported_content_types
  }

  # Additional environment variables
  environment_variables = {
    LOG_LEVEL                  = var.log_level
    ENABLE_XRAY_TRACING        = "true"
    ENABLE_PERFORMANCE_METRICS = "true"
    CHATBOT_NAME               = var.chatbot_name
    MAX_CONVERSATION_HISTORY   = var.max_conversation_history
  }

  # Performance configuration
  provisioned_concurrency_config = var.lambda_enable_provisioned_concurrency ? {
    provisioned_concurrent_executions = var.lambda_provisioned_concurrency
  } : null

  # VPC configuration (if provided)
  vpc_config = var.lambda_vpc_config

  # Monitoring
  enable_dlq            = true
  enable_xray_tracing   = true
  enable_insights       = true
  log_retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Component = "ai-inference-engine"
    Purpose   = "model-execution-vector-search"
  })

  # Ensure OpenSearch is ready before Lambda
  depends_on = [
    module.opensearch_vector_db
  ]
}

# IAM policy to allow Lambda to access OpenSearch Serverless
resource "aws_iam_policy" "lambda_opensearch_access" {
  name        = "${var.project_name}-lambda-opensearch-access-${var.environment}"
  description = "Allow Lambda to access OpenSearch Serverless collection"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = module.opensearch_vector_db.collection_arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_opensearch_access" {
  role       = module.ai_lambda.role_name
  policy_arn = aws_iam_policy.lambda_opensearch_access.arn
}

# Optional: S3 Vector Storage for backup and batch processing
module "vector_storage_backup" {
  count  = var.enable_s3_backup ? 1 : 0
  source = "../modules/s3-vector-storage"

  providers = {
    aws.replication = aws.replication
  }

  project_name          = "${var.project_name}-backup"
  environment           = var.environment
  enable_versioning     = true
  enable_replication    = var.s3_enable_replication
  replication_region    = var.replication_region
  enable_access_logging = false # Backup bucket doesn't need access logging
  force_destroy         = var.s3_force_destroy

  lifecycle_rules = [
    {
      id     = "vector_backup_lifecycle"
      status = "Enabled"

      transitions = [
        {
          days          = 7
          storage_class = "STANDARD_IA"
        },
        {
          days          = 30
          storage_class = "GLACIER"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]

  tags = merge(local.common_tags, {
    Component = "vector-backup-storage"
    Purpose   = "batch-processing-backup"
  })
}

# IAM policy to allow Lambda to access the S3 vector storage (optional, only if S3 backup is enabled)
resource "aws_iam_policy" "lambda_s3_vector_access" {
  count       = var.enable_s3_backup ? 1 : 0
  name        = "${var.project_name}-lambda-s3-vector-access-${var.environment}"
  description = "Allow Lambda to access S3 vector storage bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.vector_storage_backup[0].bucket_arn,
          "${module.vector_storage_backup[0].bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = module.vector_storage_backup[0].kms_key_arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_s3_vector_access" {
  count      = var.enable_s3_backup ? 1 : 0
  role       = module.ai_lambda.role_name
  policy_arn = aws_iam_policy.lambda_s3_vector_access[0].arn
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "ai_chatbot" {
  dashboard_name = "${var.project_name}-ai-chatbot-${var.environment}"

  dashboard_body = jsonencode({
    widgets = concat([
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.ai_lambda.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", module.ai_lambda.function_name],
            ["AWS/Lambda", "Duration", "FunctionName", module.ai_lambda.function_name],
            ["AWS/Lambda", "Throttles", "FunctionName", module.ai_lambda.function_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Function Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AOSS", "SearchRequestCount", "CollectionName", module.opensearch_vector_db.collection_name],
            ["AWS/AOSS", "SearchLatency", "CollectionName", module.opensearch_vector_db.collection_name],
            ["AWS/AOSS", "IndexRequestCount", "CollectionName", module.opensearch_vector_db.collection_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "OpenSearch Vector Database Metrics"
          period  = 300
        }
      }
      ], var.enable_s3_backup ? [
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", module.vector_storage_backup[0].bucket_name, "StorageType", "StandardStorage"],
            ["AWS/S3", "NumberOfObjects", "BucketName", module.vector_storage_backup[0].bucket_name, "StorageType", "AllStorageTypes"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "S3 Backup Storage Metrics (Optional)"
          period  = 3600
        }
      }
    ] : [])
  })
}

# SNS topic for alerts (optional)
resource "aws_sns_topic" "alerts" {
  count = var.enable_alerting ? 1 : 0
  name  = "${var.project_name}-ai-chatbot-alerts-${var.environment}"

  tags = merge(local.common_tags, {
    Component = "alerting"
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.enable_alerting && var.alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}
