variable "pipeline_name" {
  description = "Name of the OpenSearch Ingestion pipeline"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.pipeline_name))
    error_message = "Pipeline name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "s3_bucket_name" {
  description = "S3 bucket name containing the source data"
  type        = string
}

variable "opensearch_endpoint" {
  description = "OpenSearch Serverless collection endpoint URL"
  type        = string

  validation {
    condition     = can(regex("^https://.*\\.aoss\\.amazonaws\\.com$", var.opensearch_endpoint))
    error_message = "OpenSearch endpoint must be a valid AOSS endpoint URL."
  }
}

variable "network_policy_name" {
  description = "Network policy name for the AOSS collection"
  type        = string
}

variable "index_name" {
  description = "Index name in OpenSearch where documents will be stored"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_-]+$", var.index_name))
    error_message = "Index name must contain only lowercase letters, numbers, underscores, and hyphens."
  }
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
}

variable "scan_start_time" {
  description = "Start time for S3 scan in ISO 8601 format (e.g., 2025-06-01T00:00:00)"
  type        = string
  default     = null

  validation {
    condition     = var.scan_start_time == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$", var.scan_start_time))
    error_message = "Start time must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SS) or null for no time filter."
  }
}

variable "scan_end_time" {
  description = "End time for S3 scan in ISO 8601 format (e.g., 2025-07-31T23:59:59)"
  type        = string
  default     = null

  validation {
    condition     = var.scan_end_time == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$", var.scan_end_time))
    error_message = "End time must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SS) or null for no time filter."
  }
}

variable "min_units" {
  description = "Minimum number of OpenSearch Ingestion Service units"
  type        = number
  default     = 1

  validation {
    condition     = var.min_units >= 1 && var.min_units <= 96
    error_message = "Minimum units must be between 1 and 96."
  }
}

variable "max_units" {
  description = "Maximum number of OpenSearch Ingestion Service units"
  type        = number
  default     = 4

  validation {
    condition     = var.max_units >= 1 && var.max_units <= 96
    error_message = "Maximum units must be between 1 and 96."
  }
}

variable "enable_vpc_endpoint" {
  description = "Whether to create a VPC endpoint for OpenSearch Ingestion Service"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for OpenSearch Ingestion Service (required if enable_vpc_endpoint is true)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for OpenSearch Ingestion Service (required if enable_vpc_endpoint is true)"
  type        = list(string)
  default     = []
}

variable "log_group_name" {
  description = "CloudWatch log group name for OpenSearch Ingestion Service logs"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Whether to enable CloudWatch logging for the pipeline"
  type        = bool
  default     = true
}

variable "compression_type" {
  description = "Compression type for S3 objects (none, gzip, auto)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "gzip", "auto"], var.compression_type)
    error_message = "Compression type must be one of: none, gzip, auto."
  }
}

variable "workers_count" {
  description = "Number of worker threads for S3 processing"
  type        = number
  default     = 1

  validation {
    condition     = var.workers_count >= 1 && var.workers_count <= 10
    error_message = "Workers count must be between 1 and 10."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Validation for VPC endpoint configuration
locals {
  vpc_endpoint_validation = var.enable_vpc_endpoint && (var.vpc_id == null || length(var.subnet_ids) == 0) ? tobool("VPC ID and subnet IDs are required when enable_vpc_endpoint is true") : true
  min_max_validation      = var.min_units > var.max_units ? tobool("min_units cannot be greater than max_units") : true
}