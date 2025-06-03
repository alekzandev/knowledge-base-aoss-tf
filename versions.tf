terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Configure state locking and remote backend
terraform {
  backend "s3" {
    bucket         = "arn:aws:s3:::pandapops-tfstate"
    key            = "ai-chatbot/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
