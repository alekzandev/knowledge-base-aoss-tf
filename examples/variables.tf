# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ai-chatbot"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "ai-team"
}

variable "aws_region" {
  description = "AWS region for primary resources"
  type        = string
  default     = "us-east-1"
}

variable "replication_region" {
  description = "AWS region for cross-region replication"
  type        = string
  default     = "us-west-2"
}

# S3 Vector Storage Configuration
variable "s3_enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "s3_enable_replication" {
  description = "Enable cross-region replication for S3 bucket"
  type        = bool
  default     = false
}

variable "s3_enable_access_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "s3_force_destroy" {
  description = "Allow Terraform to destroy S3 bucket even if it contains objects (use with caution)"
  type        = bool
  default     = false
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.11"
}

variable "lambda_handler" {
  description = "Entry point for the Lambda function"
  type        = string
  default     = "app.lambda_handler"
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 3008
}

variable "lambda_architecture" {
  description = "Instruction set architecture for Lambda function"
  type        = string
  default     = "x86_64"
}

variable "lambda_source_file" {
  description = "Path to the Lambda function source code zip file"
  type        = string
  default     = null
}

variable "lambda_enable_provisioned_concurrency" {
  description = "Enable provisioned concurrency for Lambda function"
  type        = bool
  default     = false
}

variable "lambda_provisioned_concurrency" {
  description = "Number of provisioned concurrent executions"
  type        = number
  default     = 5
}

variable "lambda_vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "lambda_enable_dlq" {
  description = "Enable dead letter queue for Lambda function"
  type        = bool
  default     = true
}

variable "lambda_enable_xray" {
  description = "Enable X-Ray tracing for Lambda function"
  type        = bool
  default     = true
}

variable "lambda_enable_insights" {
  description = "Enable Lambda Insights for enhanced monitoring"
  type        = bool
  default     = true
}

variable "lambda_log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 14
}

variable "lambda_dlq_retention_seconds" {
  description = "Dead letter queue message retention period in seconds"
  type        = number
  default     = 1209600 # 14 days
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

# OpenSearch Vector Database Configuration
variable "vector_dimension" {
  description = "Dimension of the vector embeddings"
  type        = number
  default     = 1536 # OpenAI text-embedding-ada-002
}

variable "vector_similarity_metric" {
  description = "Similarity metric for vector search (cosine, l2, inner_product)"
  type        = string
  default     = "cosine"
}

variable "vector_engine" {
  description = "Vector search engine (nmslib or faiss)"
  type        = string
  default     = "nmslib"
}

variable "opensearch_index_name" {
  description = "Name of the OpenSearch index for vectors"
  type        = string
  default     = "ai-chatbot-knowledge-base"
}

variable "opensearch_shards" {
  description = "Number of shards for the OpenSearch index"
  type        = number
  default     = 2
}

variable "opensearch_replicas" {
  description = "Number of replicas for the OpenSearch index"
  type        = number
  default     = 1
}

variable "opensearch_create_vpc_endpoint" {
  description = "Whether to create VPC endpoint for OpenSearch"
  type        = bool
  default     = false
}

variable "opensearch_security_group_ids" {
  description = "Security group IDs for OpenSearch VPC endpoint"
  type        = list(string)
  default     = []
}

variable "opensearch_collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
  default     = "vectors"
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.opensearch_collection_name)) && length(var.opensearch_collection_name) <= 28
    error_message = "Collection name must be 3-28 characters, start and end with alphanumeric characters, and contain only lowercase letters, numbers, and hyphens."
  }
}

# Additional OpenSearch Configuration
variable "opensearch_vector_field" {
  description = "Name of the vector field in OpenSearch documents"
  type        = string
  default     = "content_vector"
}

variable "opensearch_data_access_principals" {
  description = "List of principal ARNs that will have data access to OpenSearch"
  type        = list(string)
  default     = []
}

variable "opensearch_enable_public_access" {
  description = "Whether to enable public access to OpenSearch collection"
  type        = bool
  default     = false
}

variable "opensearch_enable_saml_auth" {
  description = "Whether to enable SAML authentication for OpenSearch"
  type        = bool
  default     = false
}

# Vector Search Configuration
variable "similarity_threshold" {
  description = "Minimum similarity threshold for search results"
  type        = number
  default     = 0.8
}

variable "max_search_results" {
  description = "Maximum number of search results to return"
  type        = number
  default     = 10
}

# AI Model Configuration
variable "embedding_model_id" {
  description = "Bedrock model ID for text embeddings"
  type        = string
  default     = "amazon.titan-embed-text-v1"
}

variable "text_model_id" {
  description = "Bedrock model ID for text generation"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "max_tokens" {
  description = "Maximum tokens for model responses"
  type        = number
  default     = 4000
}

variable "temperature" {
  description = "Model temperature for text generation"
  type        = number
  default     = 0.1
}

# Knowledge Base Configuration
variable "chunk_size" {
  description = "Size of text chunks for processing"
  type        = number
  default     = 1000
}

variable "chunk_overlap" {
  description = "Overlap between text chunks"
  type        = number
  default     = 200
}

variable "min_relevance_score" {
  description = "Minimum relevance score for knowledge base results"
  type        = number
  default     = 0.7
}

variable "supported_content_types" {
  description = "Supported content types for document processing"
  type        = list(string)
  default     = ["text/plain", "text/markdown", "application/pdf", "text/html"]
}

# Application Configuration
variable "log_level" {
  description = "Logging level for the application"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}

variable "chatbot_name" {
  description = "Name of the chatbot application"
  type        = string
  default     = "AI Assistant"
}

variable "max_conversation_history" {
  description = "Maximum number of conversation turns to maintain in history"
  type        = number
  default     = 10
}

# Backup and Disaster Recovery
variable "enable_s3_backup" {
  description = "Whether to enable S3 backup for vector data"
  type        = bool
  default     = false
}

# VPC Configuration (Optional)
variable "vpc_id" {
  description = "VPC ID for resources (optional)"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for VPC resources"
  type        = list(string)
  default     = []
}

# Monitoring and Alerting
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

variable "alarm_notification_arns" {
  description = "SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "enable_alerting" {
  description = "Whether to enable SNS alerting"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = null
}
