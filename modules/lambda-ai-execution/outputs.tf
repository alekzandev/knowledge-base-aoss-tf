output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.ai_execution.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.ai_execution.arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.ai_execution.invoke_arn
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.ai_execution.qualified_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

output "dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "URL of the dead letter queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "provisioned_concurrency_config" {
  description = "Provisioned concurrency configuration"
  value = var.provisioned_concurrency_config != null ? {
    function_name                     = aws_lambda_function.ai_execution.function_name
    provisioned_concurrent_executions = var.provisioned_concurrency_config.provisioned_concurrent_executions
  } : null
}

# OpenSearch Integration Outputs
output "opensearch_configuration" {
  description = "OpenSearch configuration used by the Lambda function"
  value = var.opensearch_endpoint != null ? {
    endpoint           = var.opensearch_endpoint
    collection_name    = var.opensearch_collection_name
    index_name        = var.opensearch_index_name
    vector_field      = var.opensearch_vector_field
    vector_dimension  = var.opensearch_vector_dimension
  } : null
}

output "vector_search_configuration" {
  description = "Vector search configuration"
  value = {
    similarity_threshold = var.vector_search_config.similarity_threshold
    max_results         = var.vector_search_config.max_results
    search_timeout      = var.vector_search_config.search_timeout
    enable_filtering    = var.vector_search_config.enable_filtering
  }
}

output "bedrock_model_configuration" {
  description = "Bedrock model configuration"
  value = {
    embedding_model_id = var.bedrock_model_config.embedding_model_id
    text_model_id     = var.bedrock_model_config.text_model_id
    max_tokens        = var.bedrock_model_config.max_tokens
    temperature       = var.bedrock_model_config.temperature
  }
}

output "knowledge_base_configuration" {
  description = "Knowledge base configuration"
  value = {
    chunk_size           = var.knowledge_base_config.chunk_size
    chunk_overlap        = var.knowledge_base_config.chunk_overlap
    min_relevance_score  = var.knowledge_base_config.min_relevance_score
    enable_metadata_filtering = var.knowledge_base_config.enable_metadata_filtering
    supported_content_types = var.knowledge_base_config.supported_content_types
  }
}

# Environment Variables for Integration
output "environment_variables" {
  description = "Environment variables set for the Lambda function"
  value = var.opensearch_endpoint != null ? {
    opensearch_endpoint = var.opensearch_endpoint
    collection_name    = var.opensearch_collection_name
    index_name        = var.opensearch_index_name
    vector_dimension  = var.opensearch_vector_dimension
    project_name      = var.project_name
    environment       = var.environment
  } : {}
  sensitive = false
}

# Monitoring Resources
output "monitoring_resources" {
  description = "Monitoring resources created for the Lambda function"
  value = {
    log_group_name    = aws_cloudwatch_log_group.lambda.name
    metric_filters = [
      aws_cloudwatch_log_metric_filter.error_count.name,
      aws_cloudwatch_log_metric_filter.timeout_count.name
    ]
    alarms = [
      aws_cloudwatch_metric_alarm.error_rate.alarm_name,
      aws_cloudwatch_metric_alarm.duration.alarm_name
    ]
  }
}
