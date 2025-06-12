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

  tags = local.common_tags
}

# IAM policy for S3 access
resource "aws_iam_policy" "osis_s3_policy" {
  name        = "OSIS-S3-Access-${var.pipeline_name}"
  description = "IAM policy for OpenSearch Ingestion Service to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Sid      = "AllowS3ListAllBuckets"
        Effect   = "Allow"
        Action   = "s3:ListAllMyBuckets"
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for OpenSearch Serverless access
resource "aws_iam_policy" "osis_aoss_policy" {
  name        = "OSIS-AOSS-Access-${var.pipeline_name}"
  description = "IAM policy for OpenSearch Ingestion Service to access OpenSearch Serverless"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAOSSAccess"
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll",
          "aoss:BatchGetCollection",
          "aoss:GetSecurityPolicy"
        ]
        Resource = [
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:collection/*"
        ]
      },
      {
        Sid      = "AllowDashboardAccess"
        Effect   = "Allow"
        Action   = "aoss:DashboardsAccessAll"
        Resource = "*"
      },
      {
        Sid    = "AllowSecurityPolicyAccess"
        Effect = "Allow"
        Action = [
          "aoss:CreateSecurityPolicy",
          "aoss:UpdateSecurityPolicy",
          "aoss:GetSecurityPolicy"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aoss:collection"     = var.collection_name
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for CloudWatch Logs access (when logging is enabled)
resource "aws_iam_policy" "osis_logs_policy" {
  count       = var.enable_logging ? 1 : 0
  name        = "OSIS-Logs-Access-${var.pipeline_name}"
  description = "IAM policy for OpenSearch Ingestion Service to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}*"
      }
    ]
  })

  tags = local.common_tags
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

# Attach CloudWatch Logs policy to role (when logging is enabled)
resource "aws_iam_role_policy_attachment" "osis_logs_attachment" {
  count      = var.enable_logging ? 1 : 0
  role       = aws_iam_role.osis_role.name
  policy_arn = aws_iam_policy.osis_logs_policy[0].arn
}