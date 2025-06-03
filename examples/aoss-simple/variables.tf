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