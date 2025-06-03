# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for consistent naming and tagging
locals {
  bucket_name = "${var.project_name}-vector-storage-${var.environment}-${random_id.bucket_suffix.hex}"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Module      = "s3-vector-storage"
    ManagedBy   = "terraform"
    Purpose     = "vector-embeddings-storage"
  })
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3_encryption" {
  description             = "KMS key for S3 vector storage encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_kms_alias" "s3_encryption" {
  name          = "alias/${var.project_name}-s3-vector-storage-${var.environment}"
  target_key_id = aws_kms_key.s3_encryption.key_id
}

# Access logging bucket (conditional)
resource "aws_s3_bucket" "access_logs" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = "${local.bucket_name}-access-logs"
  
  tags = merge(local.common_tags, {
    Name    = "${local.bucket_name}-access-logs"
    Purpose = "access-logging"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Main vector storage bucket
resource "aws_s3_bucket" "vector_storage" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  
  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "vector_storage" {
  bucket = aws_s3_bucket.vector_storage.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vector_storage" {
  bucket = aws_s3_bucket.vector_storage.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "vector_storage" {
  bucket = aws_s3_bucket.vector_storage.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Access logging configuration
resource "aws_s3_bucket_logging" "vector_storage" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.vector_storage.id
  
  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "access-logs/"
}

# Intelligent tiering configuration
resource "aws_s3_bucket_intelligent_tiering_configuration" "vector_storage" {
  bucket = aws_s3_bucket.vector_storage.id
  name   = "EntireBucket"
  status = var.intelligent_tiering_status
  
  filter {
    prefix = ""
  }
  
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "vector_storage" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.vector_storage.id
  
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status
      
      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
      
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
      
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }
    }
  }
}

# Cross-region replication (conditional)
resource "aws_s3_bucket" "replication" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replication
  bucket   = "${local.bucket_name}-replica"
  
  tags = merge(local.common_tags, {
    Name    = "${local.bucket_name}-replica"
    Purpose = "cross-region-replication"
  })
}

resource "aws_s3_bucket_versioning" "replication" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replication
  bucket   = aws_s3_bucket.replication[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.project_name}-s3-replication-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.project_name}-s3-replication-policy-${var.environment}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.vector_storage.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.vector_storage.arn
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.replication[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_replication ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  count      = var.enable_replication ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.vector_storage]
  
  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.vector_storage.id
  
  rule {
    id     = "ReplicateEverything"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.replication[0].arn
      storage_class = "STANDARD_IA"
    }
  }
}
