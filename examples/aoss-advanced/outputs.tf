output "collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.opensearch_collection.collection_endpoint
}

output "collection_arn" {
  description = "OpenSearch Serverless collection ARN"
  value       = module.opensearch_collection.collection_arn
}

output "collection_id" {
  description = "OpenSearch Serverless collection ID"
  value       = module.opensearch_collection.collection_id
}

output "collection_name" {
  description = "OpenSearch Serverless collection name"
  value       = module.opensearch_collection.collection_name
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint"
  value       = module.opensearch_collection.dashboard_endpoint
}

output "kms_key_id" {
  description = "KMS key ID (if customer-managed encryption is enabled)"
  value       = var.use_customer_managed_kms ? aws_kms_key.opensearch[0].id : null
}

output "kms_key_arn" {
  description = "KMS key ARN (if customer-managed encryption is enabled)"
  value       = var.use_customer_managed_kms ? aws_kms_key.opensearch[0].arn : null
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN (if created)"
  value       = var.create_lambda_role ? aws_iam_role.lambda_opensearch[0].arn : null
}

output "lambda_role_name" {
  description = "Lambda execution role name (if created)"
  value       = var.create_lambda_role ? aws_iam_role.lambda_opensearch[0].name : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts (if enabled)"
  value       = var.enable_alerting ? aws_sns_topic.opensearch_alerts[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name (if enabled)"
  value       = var.enable_logging ? aws_cloudwatch_log_group.opensearch_logs[0].name : null
}

output "data_access_policy_name" {
  description = "Name of the data access policy"
  value       = module.opensearch_collection.data_access_policy_name
}

output "network_policy_name" {
  description = "Name of the network security policy"
  value       = module.opensearch_collection.network_policy_name
}

output "encryption_policy_name" {
  description = "Name of the encryption security policy"
  value       = module.opensearch_collection.encryption_policy_name
}
