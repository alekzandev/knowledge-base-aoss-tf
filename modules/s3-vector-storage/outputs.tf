output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.vector_storage.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.vector_storage.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.vector_storage.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.vector_storage.bucket_regional_domain_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.s3_encryption.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for encryption"
  value       = aws_kms_key.s3_encryption.key_id
}

output "access_logging_bucket_name" {
  description = "Name of the access logging bucket"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].id : null
}

output "replication_bucket_name" {
  description = "Name of the replication bucket"
  value       = var.enable_replication ? aws_s3_bucket.replication[0].id : null
}
