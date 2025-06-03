# OpenSearch Serverless Vector Database Module
# Optimized for near real-time vector similarity search

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for AWS region
data "aws_region" "current" {}

# OpenSearch Serverless Collection for vector search
resource "aws_opensearchserverless_collection" "vector_db" {
  name        = "${var.collection_name}-${var.environment}"
  type        = "VECTORSEARCH"
  description = "Vector database collection for AI chatbot embeddings - ${var.environment}"

  tags = merge(var.common_tags, {
    Name = "${var.collection_name}-${var.environment}"
    Type = "VectorSearch"
  })

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data_access
  ]
}

# Encryption policy for the collection
resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "${var.collection_name}-enc-${var.environment}"
  type        = "encryption"
  description = "Encryption policy for vector database collection"

  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}-${var.environment}"
        ]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = var.use_aws_owned_key
  })
}

# Network policy for the collection
resource "aws_opensearchserverless_security_policy" "network" {
  name        = "${var.collection_name}-net-${var.environment}"
  type        = "network"
  description = "Network policy for vector database collection"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${var.collection_name}-${var.environment}"
          ]
          ResourceType = "collection"
        },
        {
          Resource = [
            "collection/${var.collection_name}-${var.environment}"
          ]
          ResourceType = "dashboard"
        }
      ]
      AllowFromPublic = var.allow_public_access
      SourceVPCEs = var.vpc_endpoint_ids
    }
  ])
}

# Data access policy for the collection
resource "aws_opensearchserverless_access_policy" "data_access" {
  name        = "${var.collection_name}-data-${var.environment}"
  type        = "data"
  description = "Data access policy for vector database collection"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = [
            "collection/${var.collection_name}-${var.environment}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
          ResourceType = "collection"
        },
        {
          Resource = [
            "index/${var.collection_name}-${var.environment}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
          ResourceType = "index"
        }
      ]
      Principal = var.principal_arns
    }
  ])
}

# VPC Endpoint for OpenSearch Serverless (if VPC access is required)
resource "aws_vpc_endpoint" "opensearch_serverless" {
  count = var.create_vpc_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.aoss"
  route_table_ids     = var.route_table_ids
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  policy = var.vpc_endpoint_policy

  tags = merge(var.common_tags, {
    Name = "${var.collection_name}-opensearch-endpoint-${var.environment}"
  })
}

# CloudWatch Log Group for OpenSearch Serverless monitoring
resource "aws_cloudwatch_log_group" "opensearch_logs" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/opensearch/serverless/${var.collection_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(var.common_tags, {
    Name = "opensearch-logs-${var.collection_name}-${var.environment}"
  })
}

# CloudWatch Dashboard for OpenSearch monitoring
resource "aws_cloudwatch_dashboard" "opensearch_dashboard" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${var.collection_name}-opensearch-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AOSS", "SearchLatency", "CollectionName", aws_opensearchserverless_collection.vector_db.name],
            [".", "SearchRate", ".", "."],
            [".", "SearchErrors", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "OpenSearch Serverless - Search Metrics"
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
            ["AWS/AOSS", "IndexingLatency", "CollectionName", aws_opensearchserverless_collection.vector_db.name],
            [".", "IndexingRate", ".", "."],
            [".", "IndexingErrors", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "OpenSearch Serverless - Indexing Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "high_search_latency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.collection_name}-high-search-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SearchLatency"
  namespace           = "AWS/AOSS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.search_latency_threshold
  alarm_description   = "This metric monitors OpenSearch search latency"
  alarm_actions       = var.alarm_actions

  dimensions = {
    CollectionName = aws_opensearchserverless_collection.vector_db.name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_search_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.collection_name}-high-search-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SearchErrors"
  namespace           = "AWS/AOSS"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.search_error_threshold
  alarm_description   = "This metric monitors OpenSearch search errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    CollectionName = aws_opensearchserverless_collection.vector_db.name
  }

  tags = var.common_tags
}

# IAM role for Lambda functions to access OpenSearch
resource "aws_iam_role" "opensearch_lambda_role" {
  count = var.create_lambda_role ? 1 : 0

  name = "${var.collection_name}-lambda-opensearch-role-${var.environment}"

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

  tags = var.common_tags
}

# IAM policy for Lambda to access OpenSearch Serverless
resource "aws_iam_role_policy" "opensearch_lambda_policy" {
  count = var.create_lambda_role ? 1 : 0

  name = "${var.collection_name}-lambda-opensearch-policy-${var.environment}"
  role = aws_iam_role.opensearch_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = aws_opensearchserverless_collection.vector_db.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Additional resources for vector search optimization

# Local values for index template configuration
locals {
  index_template_name = "${var.index_name}-template"
  index_pattern      = "${var.index_name}-*"
  
  # Vector field mapping configuration
  vector_mapping = {
    type      = "knn_vector"
    dimension = var.vector_dimension
    method = {
      name       = "hnsw"
      space_type = var.vector_similarity_metric == "cosine" ? "cosinesimil" : var.vector_similarity_metric == "l2" ? "l2" : "innerproduct"
      engine     = var.vector_engine
      parameters = {
        ef_construction = 512
        m              = 16
      }
    }
  }
  
  # Standard document mapping
  document_mapping = {
    content = {
      type     = "text"
      analyzer = "standard"
    }
    timestamp = {
      type = "date"
    }
    source = {
      type = "keyword"
    }
    category = {
      type = "keyword"
    }
    content_type = {
      type = "keyword"
    }
  }
  
  # Combine mappings based on enabled metadata fields
  full_mapping = merge(
    {
      vector_field = local.vector_mapping
    },
    local.document_mapping,
    {
      for field in var.document_metadata_fields :
      field => {
        type = "keyword"
      }
      if !contains(["content", "timestamp", "source", "category", "content_type"], field)
    }
  )
}

# Index template for vector documents (created via null_resource since AWS provider doesn't support it directly)
resource "null_resource" "index_template" {
  count = var.enable_index_template ? 1 : 0

  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.vector_db.collection_endpoint
    template_config    = jsonencode(local.full_mapping)
    template_name      = local.index_template_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for collection to be ready
      sleep 30
      
      # Create index template using AWS CLI and curl
      ENDPOINT="${aws_opensearchserverless_collection.vector_db.collection_endpoint}"
      REGION="${data.aws_region.current.name}"
      
      # Index template configuration
      cat > /tmp/index_template.json << 'EOF'
{
  "index_patterns": ["${local.index_pattern}"],
  "template": {
    "mappings": {
      "properties": ${jsonencode(local.full_mapping)}
    },
    "settings": {
      "index": {
        "number_of_shards": ${var.number_of_shards},
        "number_of_replicas": ${var.number_of_replicas},
        "refresh_interval": "${var.refresh_interval}",
        "max_result_window": ${var.max_result_window},
        "knn": true,
        "knn.algo_param.ef_search": 512
      }
    }
  }
}
EOF

      # Use AWS CLI to make signed request to OpenSearch
      aws opensearchserverless --region $REGION \
        put-index-template \
        --collection-endpoint $ENDPOINT \
        --name "${local.index_template_name}" \
        --template file:///tmp/index_template.json || true
      
      # Clean up temporary file
      rm -f /tmp/index_template.json
    EOT
  }

  depends_on = [
    aws_opensearchserverless_collection.vector_db,
    aws_opensearchserverless_access_policy.data_access
  ]
}

# Sample index creation for immediate use
resource "null_resource" "sample_index" {
  count = var.enable_index_template ? 1 : 0

  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.vector_db.collection_endpoint
    index_name         = var.index_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for template to be created
      sleep 15
      
      ENDPOINT="${aws_opensearchserverless_collection.vector_db.collection_endpoint}"
      REGION="${data.aws_region.current.name}"
      
      # Create initial index
      cat > /tmp/index_config.json << 'EOF'
{
  "mappings": {
    "properties": ${jsonencode(local.full_mapping)}
  },
  "settings": {
    "index": {
      "number_of_shards": ${var.number_of_shards},
      "number_of_replicas": ${var.number_of_replicas},
      "refresh_interval": "${var.refresh_interval}",
      "max_result_window": ${var.max_result_window},
      "knn": true,
      "knn.algo_param.ef_search": 512
    }
  }
}
EOF

      # Create the index
      aws opensearchserverless --region $REGION \
        create-index \
        --collection-endpoint $ENDPOINT \
        --index-name "${var.index_name}" \
        --index-config file:///tmp/index_config.json || true
      
      # Clean up
      rm -f /tmp/index_config.json
    EOT
  }

  depends_on = [
    null_resource.index_template
  ]
}
