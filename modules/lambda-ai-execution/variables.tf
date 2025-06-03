variable "project_name" {
  description = "Name of the project"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "Function name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.11"
  
  validation {
    condition = contains([
      "python3.11", "python3.10", "python3.9",
      "nodejs18.x", "nodejs20.x",
      "java17", "java11",
      "dotnet8", "dotnet6"
    ], var.runtime)
    error_message = "Runtime must be a supported Lambda runtime."
  }
}

variable "handler" {
  description = "Entry point for the Lambda function"
  type        = string
  default     = "app.lambda_handler"
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 1024
  
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "architecture" {
  description = "Instruction set architecture for the Lambda function"
  type        = string
  default     = "x86_64"
  
  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be either 'x86_64' or 'arm64'."
  }
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "enable_dlq" {
  description = "Enable dead letter queue for failed function invocations"
  type        = bool
  default     = true
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for the dead letter queue"
  type        = number
  default     = 1209600  # 14 days
  
  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "DLQ message retention must be between 60 seconds and 14 days."
  }
}

variable "provisioned_concurrency_config" {
  description = "Provisioned concurrency configuration"
  type = object({
    provisioned_concurrent_executions = number
  })
  default = null
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch logs retention period."
  }
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}

variable "source_code_bucket" {
  description = "S3 bucket containing the Lambda function source code"
  type        = string
  default     = null
}

variable "source_code_key" {
  description = "S3 key for the Lambda function source code zip file"
  type        = string
  default     = null
}

variable "filename" {
  description = "Local path to the Lambda function zip file"
  type        = string
  default     = null
}

variable "enable_insights" {
  description = "Enable Lambda Insights monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# OpenSearch Configuration
variable "opensearch_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  type        = string
  default     = null
}

variable "opensearch_collection_name" {
  description = "OpenSearch Serverless collection name"
  type        = string
  default     = null
}

variable "opensearch_index_name" {
  description = "OpenSearch index name for vector search"
  type        = string
  default     = "knowledge-base"
}

variable "opensearch_vector_field" {
  description = "Name of the vector field in OpenSearch documents"
  type        = string
  default     = "vector_field"
}

variable "opensearch_vector_dimension" {
  description = "Dimension of vectors in OpenSearch"
  type        = number
  default     = 1536
}

variable "enable_opensearch_access" {
  description = "Whether to enable OpenSearch access for the Lambda function"
  type        = bool
  default     = true
}

# Vector Search Configuration
variable "vector_search_config" {
  description = "Configuration for vector search operations"
  type = object({
    similarity_threshold = optional(number, 0.8)
    max_results         = optional(number, 10)
    search_timeout      = optional(number, 30)
    enable_filtering    = optional(bool, true)
  })
  default = {
    similarity_threshold = 0.8
    max_results         = 10
    search_timeout      = 30
    enable_filtering    = true
  }
}

# AI Model Configuration  
variable "bedrock_model_config" {
  description = "Configuration for Bedrock model usage"
  type = object({
    embedding_model_id = optional(string, "amazon.titan-embed-text-v1")
    text_model_id     = optional(string, "anthropic.claude-3-sonnet-20240229-v1:0")
    max_tokens        = optional(number, 4000)
    temperature       = optional(number, 0.1)
  })
  default = {
    embedding_model_id = "amazon.titan-embed-text-v1"
    text_model_id     = "anthropic.claude-3-sonnet-20240229-v1:0"
    max_tokens        = 4000
    temperature       = 0.1
  }
}

# Knowledge Base Configuration
variable "knowledge_base_config" {
  description = "Configuration for knowledge base operations"
  type = object({
    chunk_size           = optional(number, 1000)
    chunk_overlap        = optional(number, 200)
    min_relevance_score  = optional(number, 0.7)
    enable_metadata_filtering = optional(bool, true)
    supported_content_types = optional(list(string), ["text/plain", "text/markdown", "application/pdf"])
  })
  default = {
    chunk_size           = 1000
    chunk_overlap        = 200
    min_relevance_score  = 0.7
    enable_metadata_filtering = true
    supported_content_types = ["text/plain", "text/markdown", "application/pdf"]
  }
}
