variable "aws_region" {
  description = "AWS region"
  type        = string
  nullable    = false
  default     = "us-east-1"
}

variable "collection_name" {
  description = "AOSS collection name"
  type        = string
  nullable    = false
  default     = "kb-llm-collection"
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  nullable    = false
  default     = "aoss-query-lambda"
}
variable "aoss_endpoint" {
  description = "AOSS endpoint URL"
  type        = string
  nullable    = false
  default     = "https://aoss.us-east-1.amazonaws.com"
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  nullable    = false
  default     = 7
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  nullable    = true
  default     = {}
}