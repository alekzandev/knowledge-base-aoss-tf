output "collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.nequi_kb_collection.collection_endpoint
}

output "collection_arn" {
  description = "OpenSearch Serverless collection ARN"
  value       = module.nequi_kb_collection.collection_arn
}

output "collection_id" {
  description = "OpenSearch Serverless collection ID"
  value       = module.nequi_kb_collection.collection_id
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint"
  value       = module.nequi_kb_collection.dashboard_endpoint
}

output "collection_name" {
  description = "OpenSearch Serverless collection name"
  value       = module.nequi_kb_collection.collection_name
}