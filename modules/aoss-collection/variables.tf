variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "purpose" {
  description = "Purpose of the collection"
  type        = string
  default     = "knowledge-base"
}

variable "principals" {
  description = "List of principals (IAM roles/users) to grant access to the collection"
  type        = list(string)
  default     = []
}

variable "ingestion_role_arn" {
  description = "ARN of the OpenSearch Ingestion role (optional)"
  type        = string
  default     = ""
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda role for AOSS API call (optional)"
  type        = string
  default     = ""
}

variable "allow_public_access" {
  description = "Whether to allow public access to the collection"
  type        = bool
  default     = true
}

variable "collection_type" {
  description = "Type of the collection (SEARCH, TIMESERIES, or VECTORSEARCH)"
  type        = string
  default     = "VECTORSEARCH"
  
  validation {
    condition     = contains(["SEARCH", "TIMESERIES", "VECTORSEARCH"], var.collection_type)
    error_message = "Collection type must be one of: SEARCH, TIMESERIES, VECTORSEARCH."
  }
}

variable "encryption_key_type" {
  description = "Encryption key type (AWS_OWNED_KMS_KEY or CUSTOMER_MANAGED_KMS_KEY)"
  type        = string
  default     = "AWS_OWNED_KMS_KEY"
  
  validation {
    condition     = contains(["AWS_OWNED_KMS_KEY", "CUSTOMER_MANAGED_KMS_KEY"], var.encryption_key_type)
    error_message = "Encryption key type must be either AWS_OWNED_KMS_KEY or CUSTOMER_MANAGED_KMS_KEY."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for customer-managed encryption (required if encryption_key_type is CUSTOMER_MANAGED_KMS_KEY)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for the collection"
  type        = map(string)
  default     = {}
}