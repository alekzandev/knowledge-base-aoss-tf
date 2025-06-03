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

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
  default     = "nequi-kb-collection"
}

# Data access policy (allows public access)
resource "aws_opensearchserverless_access_policy" "data_access" {
  name = "${var.collection_name}-data-access"
  type = "data"

  policy = jsonencode([
    {
      "Rules" : [
        {
          "Resource" : [
            "collection/${var.collection_name}"
          ],
          "Permission" : [
            "aoss:DescribeCollectionItems",
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DeleteCollectionItems"
          ],
          "ResourceType" : "collection"
        },
        {
          "Resource" : [
            "index/${var.collection_name}/*"
          ],
          "Permission" : [
            "aoss:*"
          ],
          "ResourceType" : "index"
        }
      ],
      "Principal" : [
        "arn:aws:iam::289269610742:role/service-role/OpenSearchIngestion-role-from-s3-test-deletme"
      ]
    },
    {
      "Rules" : [
        {
          "Resource" : [
            "collection/${var.collection_name}"
          ],
          "Permission" : [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ],
          "ResourceType" : "collection"
        },
        {
          "Resource" : [
            "index/${var.collection_name}/*"
          ],
          "Permission" : [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ],
          "ResourceType" : "index"
        }
      ],
      "Principal" : [
        "arn:aws:iam::289269610742:user/hausdorff94_main",
        "arn:aws:iam::289269610742:user/hausdorff94"
      ],
      "Description" : "TerminalAdminPermissions"
    }
  ])
}

# Network policy (allows public access)
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.collection_name}-network"
  type = "network"

  policy = jsonencode([
    {
      "Rules" : [
        {
          "Resource" : [
            "collection/${var.collection_name}"
          ],
          "ResourceType" : "dashboard"
        },
        {
          "Resource" : [
            "collection/${var.collection_name}"
          ],
          "ResourceType" : "collection"
        }
      ],
      "AllowFromPublic" : true,
      "Description" : "AWSPrivateAccess"
    }
  ])
}

# Encryption policy
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.collection_name}-encryption"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

# OpenSearch Serverless Collection
resource "aws_opensearchserverless_collection" "kb_collection" {
  name = var.collection_name
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_access_policy.data_access,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_security_policy.encryption
  ]

  tags = {
    Name        = var.collection_name
    Environment = "development"
    Purpose     = "knowledge-base"
  }
}

# Outputs
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

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint"
  value       = aws_opensearchserverless_collection.kb_collection.dashboard_endpoint
}