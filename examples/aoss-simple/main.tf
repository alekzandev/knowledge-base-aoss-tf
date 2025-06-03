terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create AOSS collection using the module
module "nequi_kb_collection" {
  source = "../../modules/aoss-collection"

  collection_name = var.collection_name
  environment     = var.environment
  purpose         = "knowledge-base"

  # Grant access to specific IAM users/roles (using your actual ARNs)
  principals = [
    "arn:aws:iam::289269610742:user/hausdorff94_main",
    "arn:aws:iam::289269610742:user/hausdorff94"
  ]

  # Optional: Add ingestion role for data pipelines
  ingestion_role_arn = "arn:aws:iam::289269610742:role/service-role/OpenSearchIngestion-role-from-s3-test-deletme"

  # Security settings (matching your working config)
  allow_public_access = true
  collection_type     = "VECTORSEARCH"
  encryption_key_type = "AWS_OWNED_KMS_KEY"

  tags = {
    Project     = "nequi-chatbot"
    Team        = "ai-ml"
    ManagedBy   = "terraform"
  }
}