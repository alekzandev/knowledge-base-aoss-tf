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

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    CreatedBy   = "terraform"
    Region      = local.region
  }
}

# KMS key for customer-managed encryption (optional)
resource "aws_kms_key" "opensearch" {
  count = var.use_customer_managed_kms ? 1 : 0
  
  description             = "KMS key for OpenSearch Serverless collection ${var.collection_name}"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.collection_name}-kms-key"
  })
}

resource "aws_kms_alias" "opensearch" {
  count = var.use_customer_managed_kms ? 1 : 0
  
  name          = "alias/${var.collection_name}-opensearch"
  target_key_id = aws_kms_key.opensearch[0].key_id
}

# IAM role for Lambda function (example)
resource "aws_iam_role" "lambda_opensearch" {
  count = var.create_lambda_role ? 1 : 0
  
  name = "${var.collection_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.collection_name}-lambda-role"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.create_lambda_role ? 1 : 0
  
  role       = aws_iam_role.lambda_opensearch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create AOSS collection using the module
module "opensearch_collection" {
  source = "../../modules/aoss-collection"

  collection_name = var.collection_name
  environment     = var.environment
  purpose         = var.purpose

  # Principal configuration
  principals = concat(
    var.additional_principals,
    var.create_lambda_role ? [aws_iam_role.lambda_opensearch[0].arn] : []
  )
  
  ingestion_role_arn = var.ingestion_role_arn

  # Security settings
  allow_public_access = var.allow_public_access
  collection_type     = var.collection_type
  
  # Encryption settings
  encryption_key_type = var.use_customer_managed_kms ? "CUSTOMER_MANAGED_KMS_KEY" : "AWS_OWNED_KMS_KEY"
  kms_key_id         = var.use_customer_managed_kms ? aws_kms_key.opensearch[0].arn : ""

  tags = merge(local.common_tags, var.additional_tags)
}

# CloudWatch Log Group for monitoring
resource "aws_cloudwatch_log_group" "opensearch_logs" {
  count = var.enable_logging ? 1 : 0
  
  name              = "/aws/opensearch/collections/${var.collection_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.collection_name}-logs"
  })
}

# SNS topic for alerts (optional)
resource "aws_sns_topic" "opensearch_alerts" {
  count = var.enable_alerting ? 1 : 0
  
  name = "${var.collection_name}-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.collection_name}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count = var.enable_alerting && var.alert_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.opensearch_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch alarms for monitoring (optional)
resource "aws_cloudwatch_metric_alarm" "search_latency" {
  count = var.enable_alerting ? 1 : 0
  
  alarm_name          = "${var.collection_name}-high-search-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SearchLatency"
  namespace           = "AWS/AOSS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.search_latency_threshold
  alarm_description   = "This metric monitors opensearch search latency"
  
  dimensions = {
    CollectionName = module.opensearch_collection.collection_name
  }

  alarm_actions = var.enable_alerting ? [aws_sns_topic.opensearch_alerts[0].arn] : []

  tags = local.common_tags
}