# VPC Endpoint for OpenSearch Ingestion Service (optional)
resource "aws_opensearchserverless_vpc_endpoint" "osis_endpoint" {
  count      = var.enable_vpc_endpoint ? 1 : 0
  name       = "${var.pipeline_name}-vpc-endpoint"
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
}