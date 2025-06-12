# Test configuration for osis-pipeline module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Test module instantiation
module "test_osis_pipeline" {
  source = "./"

  pipeline_name         = "test-pipeline"
  s3_bucket_name       = "test-bucket"
  opensearch_endpoint  = "https://test.us-east-1.aoss.amazonaws.com"
  network_policy_name  = "test-policy"
  index_name           = "test-index"
  collection_name      = "test-collection"

  tags = {
    Environment = "test"
    Purpose     = "validation"
  }
}

#8Ww3DoTIWQCY3kFZd33FNGkk8sSySnP1Pmpw8TSqhVgByVORTCGwJQQJ99BFACAAAAAFtioVAAASAZDO1pcB