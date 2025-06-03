# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for consistent naming and tagging
locals {
  function_name = "${var.project_name}-${var.function_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Module      = "lambda-ai-execution"
    ManagedBy   = "terraform"
    Purpose     = "ai-model-execution"
  })
  
  # Lambda Insights layer ARN based on region
  insights_layer_arn = var.enable_insights ? "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:${var.architecture == "arm64" ? "21" : "38"}" : null
  
  # Combined layers (insights + user-provided)
  all_layers = compact(concat(
    var.lambda_layers,
    var.enable_insights ? [local.insights_layer_arn] : []
  ))
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_in_days
  
  tags = merge(local.common_tags, {
    Name = "${local.function_name}-logs"
  })
}

# Dead Letter Queue (SQS)
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0
  
  name                       = "${local.function_name}-dlq"
  message_retention_seconds  = var.dlq_message_retention_seconds
  visibility_timeout_seconds = var.timeout * 6  # 6x function timeout as recommended
  
  tags = merge(local.common_tags, {
    Name    = "${local.function_name}-dlq"
    Purpose = "dead-letter-queue"
  })
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution" {
  name = "${local.function_name}-execution-role"
  
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
  
  tags = local.common_tags
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution policy (conditional)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Insights policy (conditional)
resource "aws_iam_role_policy_attachment" "lambda_insights" {
  count      = var.enable_insights ? 1 : 0
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

# Custom IAM policy for AI services access
resource "aws_iam_policy" "ai_services_access" {
  name        = "${local.function_name}-ai-services-policy"
  description = "IAM policy for Lambda AI services access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockAccess"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels",
          "bedrock:GetModelInvocationLoggingConfiguration"
        ]
        Resource = "*"
      },
      {
        Sid    = "OpenSearchServerlessAccess"
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll",
          "aoss:DashboardsAccessAll"
        ]
        Resource = var.opensearch_endpoint != null ? [
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:collection/*"
        ] : ["*"]
        Condition = var.opensearch_collection_name != null ? {
          StringEquals = {
            "aoss:collection" = var.opensearch_collection_name
          }
        } : {}
      },
      {
        Sid    = "S3VectorStorageAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*-vector-storage-*",
          "arn:aws:s3:::*-vector-storage-*/*",
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-*",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-*/index/*"
        ]
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = [
              "AWS/Lambda",
              "AI/Chatbot",
              "VectorSearch/Performance"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ai_services_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.ai_services_access.arn
}

# DLQ access policy (conditional)
resource "aws_iam_policy" "dlq_access" {
  count = var.enable_dlq ? 1 : 0
  
  name        = "${local.function_name}-dlq-policy"
  description = "IAM policy for Lambda DLQ access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.dlq[0].arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dlq_access" {
  count      = var.enable_dlq ? 1 : 0
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.dlq_access[0].arn
}

# Lambda Function
resource "aws_lambda_function" "ai_execution" {
  function_name = local.function_name
  role         = aws_iam_role.lambda_execution.arn
  
  # Source code configuration
  filename         = var.filename
  s3_bucket        = var.source_code_bucket
  s3_key           = var.source_code_key
  source_code_hash = var.filename != null ? filebase64sha256(var.filename) : null
  
  # Runtime configuration
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = [var.architecture]
  
  # Layers
  layers = length(local.all_layers) > 0 ? local.all_layers : null
  
  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 || var.opensearch_endpoint != null ? [1] : []
    content {
      variables = merge(
        var.environment_variables,
        var.opensearch_endpoint != null ? {
          OPENSEARCH_ENDPOINT           = var.opensearch_endpoint
          OPENSEARCH_COLLECTION_NAME    = var.opensearch_collection_name
          OPENSEARCH_INDEX_NAME         = var.opensearch_index_name
          OPENSEARCH_VECTOR_FIELD       = var.opensearch_vector_field
          OPENSEARCH_VECTOR_DIMENSION   = tostring(var.opensearch_vector_dimension)
          
          # Vector search configuration
          VECTOR_SIMILARITY_THRESHOLD   = tostring(var.vector_search_config.similarity_threshold)
          VECTOR_MAX_RESULTS           = tostring(var.vector_search_config.max_results)
          VECTOR_SEARCH_TIMEOUT        = tostring(var.vector_search_config.search_timeout)
          VECTOR_ENABLE_FILTERING      = tostring(var.vector_search_config.enable_filtering)
          
          # Bedrock model configuration
          BEDROCK_EMBEDDING_MODEL_ID   = var.bedrock_model_config.embedding_model_id
          BEDROCK_TEXT_MODEL_ID        = var.bedrock_model_config.text_model_id
          BEDROCK_MAX_TOKENS          = tostring(var.bedrock_model_config.max_tokens)
          BEDROCK_TEMPERATURE         = tostring(var.bedrock_model_config.temperature)
          
          # Knowledge base configuration
          KB_CHUNK_SIZE               = tostring(var.knowledge_base_config.chunk_size)
          KB_CHUNK_OVERLAP            = tostring(var.knowledge_base_config.chunk_overlap)
          KB_MIN_RELEVANCE_SCORE      = tostring(var.knowledge_base_config.min_relevance_score)
          KB_ENABLE_METADATA_FILTERING = tostring(var.knowledge_base_config.enable_metadata_filtering)
          KB_SUPPORTED_CONTENT_TYPES  = join(",", var.knowledge_base_config.supported_content_types)
          
          # AWS configuration
          AWS_DEFAULT_REGION          = data.aws_region.current.name
          PROJECT_NAME               = var.project_name
          ENVIRONMENT                = var.environment
        } : {}
      )
    }
  }
  
  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }
  
  # Dead letter queue configuration
  dynamic "dead_letter_config" {
    for_each = var.enable_dlq ? [1] : []
    content {
      target_arn = aws_sqs_queue.dlq[0].arn
    }
  }
  
  # X-Ray tracing configuration
  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }
  
  # Ensure log group is created before function
  depends_on = [aws_cloudwatch_log_group.lambda]
  
  tags = merge(local.common_tags, {
    Name = local.function_name
  })
}

# Provisioned Concurrency (conditional)
resource "aws_lambda_provisioned_concurrency_config" "ai_execution" {
  count = var.provisioned_concurrency_config != null ? 1 : 0
  
  function_name                     = aws_lambda_function.ai_execution.function_name
  qualifier                        = "$LATEST"
  provisioned_concurrent_executions = var.provisioned_concurrency_config.provisioned_concurrent_executions
}

# CloudWatch Metric Filters for monitoring
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${local.function_name}-error-count"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"
  
  metric_transformation {
    name      = "${local.function_name}-errors"
    namespace = "AWS/Lambda/Custom"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "timeout_count" {
  name           = "${local.function_name}-timeout-count"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "Task timed out"
  
  metric_transformation {
    name      = "${local.function_name}-timeouts"
    namespace = "AWS/Lambda/Custom"
    value     = "1"
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${local.function_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda error rate"
  alarm_actions       = []  # Add SNS topic ARN for notifications
  
  dimensions = {
    FunctionName = aws_lambda_function.ai_execution.function_name
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  alarm_name          = "${local.function_name}-high-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = tostring(var.timeout * 1000 * 0.8)  # 80% of timeout
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = []  # Add SNS topic ARN for notifications
  
  dimensions = {
    FunctionName = aws_lambda_function.ai_execution.function_name
  }
  
  tags = local.common_tags
}
