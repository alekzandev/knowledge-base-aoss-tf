# OpenSearch Serverless Vector Database Module Outputs

# Collection Information
output "collection_id" {
  description = "ID of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_db.id
}

output "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_db.name
}

output "collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.vector_db.arn
}

output "collection_endpoint" {
  description = "Collection endpoint for OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.vector_db.collection_endpoint
}

output "dashboard_endpoint" {
  description = "Dashboard endpoint for OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.vector_db.dashboard_endpoint
}

# Security Policies
output "encryption_policy_version" {
  description = "Version of the encryption policy"
  value       = aws_opensearchserverless_security_policy.encryption.policy_version
}

output "network_policy_version" {
  description = "Version of the network policy"
  value       = aws_opensearchserverless_security_policy.network.policy_version
}

output "data_access_policy_version" {
  description = "Version of the data access policy"
  value       = aws_opensearchserverless_access_policy.data_access.policy_version
}

# VPC Endpoint Information
output "vpc_endpoint_id" {
  description = "ID of the VPC endpoint (if created)"
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.opensearch_serverless[0].id : null
}

output "vpc_endpoint_dns_entry" {
  description = "DNS entries for the VPC endpoint (if created)"
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.opensearch_serverless[0].dns_entry : null
}

# CloudWatch Resources
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group (if created)"
  value       = var.enable_logging ? aws_cloudwatch_log_group.opensearch_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group (if created)"
  value       = var.enable_logging ? aws_cloudwatch_log_group.opensearch_logs[0].arn : null
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard (if created)"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.opensearch_dashboard[0].dashboard_name : null
}

# IAM Resources
output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role (if created)"
  value       = var.create_lambda_role ? aws_iam_role.opensearch_lambda_role[0].arn : null
}

output "lambda_role_name" {
  description = "Name of the Lambda IAM role (if created)"
  value       = var.create_lambda_role ? aws_iam_role.opensearch_lambda_role[0].name : null
}

# Configuration Information
output "vector_configuration" {
  description = "Vector search configuration details"
  value = {
    dimension        = var.vector_dimension
    similarity_metric = var.vector_similarity_metric
    engine          = var.vector_engine
    index_name      = var.index_name
    shards          = var.number_of_shards
    replicas        = var.number_of_replicas
  }
}

output "index_template_configuration" {
  description = "Index template configuration for vector documents"
  value = var.enable_index_template ? {
    name             = "${var.index_name}-template"
    pattern          = "${var.index_name}-*"
    vector_dimension = var.vector_dimension
    similarity_metric = var.vector_similarity_metric
    engine          = var.vector_engine
    metadata_fields = var.document_metadata_fields
    refresh_interval = var.refresh_interval
    max_result_window = var.max_result_window
  } : null
}

# Connection Information for Applications
output "connection_info" {
  description = "Connection information for applications"
  value = {
    endpoint     = aws_opensearchserverless_collection.vector_db.collection_endpoint
    collection_name = aws_opensearchserverless_collection.vector_db.name
    index_name   = var.index_name
    region       = data.aws_region.current.name
    service_name = "aoss"
  }
}

# Monitoring Information
output "monitoring_resources" {
  description = "Monitoring resources created"
  value = {
    log_group_name = var.enable_logging ? aws_cloudwatch_log_group.opensearch_logs[0].name : null
    dashboard_name = var.create_dashboard ? aws_cloudwatch_dashboard.opensearch_dashboard[0].dashboard_name : null
    alarms_enabled = var.enable_alarms
    alarm_names = var.enable_alarms ? [
      aws_cloudwatch_metric_alarm.high_search_latency[0].alarm_name,
      aws_cloudwatch_metric_alarm.high_search_errors[0].alarm_name
    ] : []
  }
}

# Performance Thresholds
output "performance_thresholds" {
  description = "Performance monitoring thresholds"
  value = {
    search_latency_ms = var.search_latency_threshold
    search_errors     = var.search_error_threshold
  }
}

# Security Configuration
output "security_configuration" {
  description = "Security configuration summary"
  value = {
    aws_owned_key      = var.use_aws_owned_key
    public_access      = var.allow_public_access
    vpc_endpoint_created = var.create_vpc_endpoint
    principal_count    = length(var.principal_arns)
  }
}

# Environment Information
output "environment_info" {
  description = "Environment and deployment information"
  value = {
    environment    = var.environment
    collection_name = "${var.collection_name}-${var.environment}"
    aws_region     = data.aws_region.current.name
    aws_account_id = data.aws_caller_identity.current.account_id
  }
}
