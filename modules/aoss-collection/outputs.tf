output "collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = aws_opensearchserverless_collection.kb_collection.collection_endpoint
}

output "collection_arn" {
  description = "OpenSearch Serverless collection ARN"
  value       = aws_opensearchserverless_collection.kb_collection.arn
}

output "collection_id" {
  description = "OpenSearch Serverless collection ID"
  value       = aws_opensearchserverless_collection.kb_collection.id
}

output "collection_name" {
  description = "OpenSearch Serverless collection name"
  value       = aws_opensearchserverless_collection.kb_collection.name
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint"
  value       = aws_opensearchserverless_collection.kb_collection.dashboard_endpoint
}

output "data_access_policy_name" {
  description = "Name of the data access policy"
  value       = aws_opensearchserverless_access_policy.data_access.name
}

output "network_policy_name" {
  description = "Name of the network security policy"
  value       = aws_opensearchserverless_security_policy.network.name
}

output "encryption_policy_name" {
  description = "Name of the encryption security policy"
  value       = aws_opensearchserverless_security_policy.encryption.name
}