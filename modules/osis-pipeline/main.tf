# Local values for cleaner code
locals {
  common_tags = merge(
    {
      Name      = var.pipeline_name
      Module    = "osis-pipeline"
      ManagedBy = "terraform"
    },
    var.tags
  )

  # Create log group name if not provided
  log_group_name = var.log_group_name != null ? var.log_group_name : "/aws/opensearchingestion/${var.pipeline_name}"

  # Build scan configuration
  scan_config = {
    buckets = [
      {
        bucket = merge(
          {
            name = var.s3_bucket_name
          },
          var.scan_start_time != null ? { start_time = var.scan_start_time } : {},
          var.scan_end_time != null ? { end_time = var.scan_end_time } : {}
        )
      }
    ]
  }
}

# CloudWatch Log Group for OSIS pipeline
resource "aws_cloudwatch_log_group" "osis_log_group" {
  count             = var.enable_logging ? 1 : 0
  name              = local.log_group_name
  retention_in_days = 30

  tags = local.common_tags
}

# OpenSearch Ingestion Pipeline
resource "aws_osis_pipeline" "ingestion_pipeline" {
  pipeline_name = var.pipeline_name

  dynamic "log_publishing_options" {
    for_each = var.enable_logging ? [1] : []
    content {
      is_logging_enabled = true
      cloudwatch_log_destination {
        log_group = local.log_group_name
      }
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
          scan            = local.scan_config
          aws = {
            region       = data.aws_region.current.name
            sts_role_arn = aws_iam_role.osis_role.arn
          }
          codec = {
            ndjson = {}
          }
          compression = var.compression_type
          workers     = tostring(var.workers_count)
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
              region       = data.aws_region.current.name
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

  min_units = var.min_units
  max_units = var.max_units

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.osis_s3_attachment,
    aws_iam_role_policy_attachment.osis_aoss_attachment,
    aws_cloudwatch_log_group.osis_log_group
  ]
}