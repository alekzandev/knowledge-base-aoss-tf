# OpenSearch Serverless Collection - Based on working configuration
resource "aws_opensearchserverless_collection" "kb_collection" {
  name = var.collection_name
  type = var.collection_type

  depends_on = [
    aws_opensearchserverless_access_policy.data_access,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_security_policy.encryption
  ]

  tags = merge({
    Name        = var.collection_name
    Environment = var.environment
    Purpose     = var.purpose
  }, var.tags)
}