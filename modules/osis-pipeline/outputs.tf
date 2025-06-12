output "pipeline_arn" {
  description = "ARN of the OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.ingestion_pipeline.pipeline_arn
}

output "pipeline_name" {
  description = "Name of the OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.ingestion_pipeline.pipeline_name
}

output "pipeline_endpoint" {
  description = "Endpoint URLs of the OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.ingestion_pipeline.ingest_endpoint_urls
}

output "osis_role_arn" {
  description = "ARN of the IAM role used by the OpenSearch Ingestion Service"
  value       = aws_iam_role.osis_role.arn
}

output "osis_role_name" {
  description = "Name of the IAM role used by the OpenSearch Ingestion Service"
  value       = aws_iam_role.osis_role.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group (if logging is enabled)"
  value       = var.enable_logging ? local.log_group_name : null
}

output "vpc_endpoint_id" {
  description = "ID of the VPC endpoint (if created)"
  value       = var.enable_vpc_endpoint ? aws_opensearchserverless_vpc_endpoint.osis_endpoint[0].id : null
}