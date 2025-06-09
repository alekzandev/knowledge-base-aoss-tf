variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
  default     = "nequi-kb-collection"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# Variables
variable "ingestion_role_arn" {
  description = "ARN of the IAM role for OpenSearch Ingestion"
  type        = string
  default     = "arn:aws:iam::289269610742:role/OpenSearchIngestion-nequi-kb-ingest-pipeline-role"
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda role for AOSS API call (optional)"
  type        = string
  default     = "arn:aws:iam::289269610742:role/role-lambda-aoss-query"
}