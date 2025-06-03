variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "nequi-ai-chatbot"
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
  default     = "nequi-production-vectors"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "ai-team"
}

variable "purpose" {
  description = "Purpose of the collection"
  type        = string
  default     = "production-knowledge-base"
}

variable "additional_principals" {
  description = "Additional IAM principals to grant access to the collection"
  type        = list(string)
  default = [
    "arn:aws:iam::289269610742:user/hausdorff94_main",
    "arn:aws:iam::289269610742:user/hausdorff94"
  ]
}

variable "ingestion_role_arn" {
  description = "ARN of the OpenSearch Ingestion role"
  type        = string
  default     = ""
}

variable "allow_public_access" {
  description = "Whether to allow public access to the collection"
  type        = bool
  default     = false
}

variable "collection_type" {
  description = "Type of the collection"
  type        = string
  default     = "VECTORSEARCH"
}

variable "use_customer_managed_kms" {
  description = "Whether to use customer-managed KMS key for encryption"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "create_lambda_role" {
  description = "Whether to create a Lambda execution role for OpenSearch access"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether to enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_alerting" {
  description = "Whether to enable CloudWatch alarms and SNS notifications"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "search_latency_threshold" {
  description = "Search latency threshold in milliseconds for alarms"
  type        = number
  default     = 1000
}

variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    CostCenter = "engineering"
    Team       = "ai-ml"
    Compliance = "SOC2"
  }
}
