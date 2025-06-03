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

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_region" {
  description = "Target region for cross-region replication"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket"
  type = list(object({
    id     = string
    status = string
    
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    
    expiration = optional(object({
      days = number
    }))
    
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
  }))
  default = []
}

variable "intelligent_tiering_status" {
  description = "Status of S3 Intelligent Tiering"
  type        = string
  default     = "Enabled"
  
  validation {
    condition     = contains(["Enabled", "Disabled"], var.intelligent_tiering_status)
    error_message = "Intelligent tiering status must be either 'Enabled' or 'Disabled'."
  }
}

variable "enable_access_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
