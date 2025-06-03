# OpenSearch Vector Database Outputs (Primary)
output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.opensearch_vector_db.collection_endpoint
}

output "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = module.opensearch_vector_db.collection_arn
}

output "opensearch_collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  value       = module.opensearch_vector_db.collection_name
}

output "opensearch_dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = module.opensearch_vector_db.dashboard_endpoint
}

output "opensearch_connection_info" {
  description = "Complete connection information for OpenSearch"
  value       = module.opensearch_vector_db.connection_info
}

output "opensearch_vector_configuration" {
  description = "Vector search configuration details"
  value       = module.opensearch_vector_db.vector_configuration
}

output "opensearch_monitoring_resources" {
  description = "OpenSearch monitoring resources"
  value       = module.opensearch_vector_db.monitoring_resources
}

# Lambda AI Execution Outputs
output "lambda_function_name" {
  description = "Name of the Lambda AI execution function"
  value       = module.ai_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda AI execution function"
  value       = module.ai_lambda.function_arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda AI execution function"
  value       = module.ai_lambda.function_invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.ai_lambda.role_arn
}

output "lambda_opensearch_configuration" {
  description = "Lambda OpenSearch integration configuration"
  value       = module.ai_lambda.opensearch_configuration
}

output "lambda_vector_search_configuration" {
  description = "Lambda vector search configuration"
  value       = module.ai_lambda.vector_search_configuration
}

output "lambda_bedrock_configuration" {
  description = "Lambda Bedrock model configuration"
  value       = module.ai_lambda.bedrock_model_configuration
}

output "lambda_monitoring_resources" {
  description = "Lambda monitoring resources"
  value       = module.ai_lambda.monitoring_resources
}

# S3 Backup Storage Outputs (Optional)
output "backup_storage_bucket_name" {
  description = "Name of the S3 backup storage bucket (if enabled)"
  value       = var.enable_s3_backup ? module.vector_storage_backup[0].bucket_name : null
}

output "backup_storage_bucket_arn" {
  description = "ARN of the S3 backup storage bucket (if enabled)"
  value       = var.enable_s3_backup ? module.vector_storage_backup[0].bucket_arn : null
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = module.ai_lambda.log_group_name
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.ai_chatbot.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.enable_alerting ? aws_sns_topic.alerts[0].arn : null
}

# Integration Information
output "integration_info" {
  description = "Information for integrating with the AI chatbot infrastructure"
  value = {
    # OpenSearch information (always available)
    opensearch_collection_endpoint = module.opensearch_vector_db.collection_endpoint
    opensearch_collection_arn      = module.opensearch_vector_db.collection_arn
    opensearch_collection_name     = module.opensearch_vector_db.collection_name

    # Lambda information
    lambda_function_arn = module.ai_lambda.function_arn
    lambda_invoke_arn   = module.ai_lambda.function_invoke_arn
    log_group_name      = module.ai_lambda.log_group_name
    dlq_arn             = module.ai_lambda.dlq_arn

    # S3 backup information (conditional)
    s3_bucket_name = var.enable_s3_backup ? module.vector_storage_backup[0].bucket_name : null
    kms_key_arn    = var.enable_s3_backup ? module.vector_storage_backup[0].kms_key_arn : null
  }
}
