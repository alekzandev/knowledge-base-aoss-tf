# OpenSearch Serverless Vector Database Module Variables

# Collection Configuration
variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
  default     = "vector-knowledge-base"
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.collection_name)) && length(var.collection_name) <= 32
    error_message = "Collection name must be 3-32 characters, start and end with alphanumeric characters, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

# Security Configuration
variable "principal_arns" {
  description = "List of principal ARNs that will have access to the OpenSearch collection"
  type        = list(string)
  default     = []
}

variable "use_aws_owned_key" {
  description = "Whether to use AWS-owned KMS key for encryption"
  type        = bool
  default     = true
}

variable "allow_public_access" {
  description = "Whether to allow public access to the collection"
  type        = bool
  default     = false
}

# VPC Configuration
variable "create_vpc_endpoint" {
  description = "Whether to create a VPC endpoint for OpenSearch Serverless"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the VPC endpoint will be created"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the VPC endpoint"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for the VPC endpoint"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs for the VPC endpoint"
  type        = list(string)
  default     = []
}

variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs for network policy"
  type        = list(string)
  default     = []
}

variable "vpc_endpoint_policy" {
  description = "VPC endpoint policy document"
  type        = string
  default     = null
}

# Monitoring Configuration
variable "enable_logging" {
  description = "Whether to enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch logs"
  type        = string
  default     = null
}

variable "create_dashboard" {
  description = "Whether to create a CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Whether to enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "search_latency_threshold" {
  description = "Threshold for search latency alarm in milliseconds"
  type        = number
  default     = 1000
}

variable "search_error_threshold" {
  description = "Threshold for search error alarm"
  type        = number
  default     = 5
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# IAM Configuration
variable "create_lambda_role" {
  description = "Whether to create an IAM role for Lambda functions"
  type        = bool
  default     = false
}

# Vector Search Configuration
variable "vector_dimension" {
  description = "Dimension of the vector embeddings"
  type        = number
  default     = 1536
  
  validation {
    condition     = var.vector_dimension > 0 && var.vector_dimension <= 10000
    error_message = "Vector dimension must be between 1 and 10000."
  }
}

variable "vector_similarity_metric" {
  description = "Similarity metric for vector search (l2, cosine, or inner_product)"
  type        = string
  default     = "cosine"
  
  validation {
    condition     = contains(["l2", "cosine", "inner_product"], var.vector_similarity_metric)
    error_message = "Vector similarity metric must be one of: l2, cosine, inner_product."
  }
}

variable "vector_engine" {
  description = "Vector search engine (nmslib or faiss)"
  type        = string
  default     = "nmslib"
  
  validation {
    condition     = contains(["nmslib", "faiss"], var.vector_engine)
    error_message = "Vector engine must be either 'nmslib' or 'faiss'."
  }
}

# Index Configuration
variable "index_name" {
  description = "Name of the vector index"
  type        = string
  default     = "knowledge-base-vectors"
}

variable "number_of_shards" {
  description = "Number of shards for the index"
  type        = number
  default     = 2
  
  validation {
    condition     = var.number_of_shards > 0 && var.number_of_shards <= 100
    error_message = "Number of shards must be between 1 and 100."
  }
}

variable "number_of_replicas" {
  description = "Number of replicas for the index"
  type        = number
  default     = 1
  
  validation {
    condition     = var.number_of_replicas >= 0 && var.number_of_replicas <= 10
    error_message = "Number of replicas must be between 0 and 10."
  }
}

# Performance Configuration
variable "refresh_interval" {
  description = "Index refresh interval in seconds"
  type        = string
  default     = "1s"
}

variable "max_result_window" {
  description = "Maximum number of documents that can be returned in a single search request"
  type        = number
  default     = 10000
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Module      = "opensearch-vector-db"
    Purpose     = "AI-ChatBot-VectorDB"
  }
}

# Additional Configuration
variable "enable_index_template" {
  description = "Whether to create an index template for vector documents"
  type        = bool
  default     = true
}

variable "document_metadata_fields" {
  description = "Additional metadata fields to include in vector documents"
  type        = list(string)
  default     = ["source", "timestamp", "category", "content_type"]
}

variable "enable_auto_scaling" {
  description = "Whether to enable auto-scaling for the collection"
  type        = bool
  default     = true
}

variable "min_capacity_units" {
  description = "Minimum capacity units for auto-scaling"
  type        = number
  default     = 2
}

variable "max_capacity_units" {
  description = "Maximum capacity units for auto-scaling"
  type        = number
  default     = 10
}
