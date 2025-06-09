# Data access policy - Based on working configuration
resource "aws_opensearchserverless_access_policy" "data_access" {
  name = "${substr(var.collection_name, 0, 20)}-data"
  type = "data"

  policy = jsonencode([
    for policy_block in [
      # Optional ingestion role permissions (if provided)
      var.ingestion_role_arn != "" ? {
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
          var.ingestion_role_arn,
          var.lambda_role_arn != "" ? var.lambda_role_arn : null
        ]
      } : null,
      # Main principals permissions
      length(var.principals) > 0 ? {
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
        "Principal" : var.principals,
        "Description" : "AdminPermissions"
      } : null
    ] : policy_block if policy_block != null
  ])
}

# Network policy - Based on working configuration
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${substr(var.collection_name, 0, 20)}-net"
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
      "AllowFromPublic" : var.allow_public_access,
      "Description" : var.allow_public_access ? "PublicAccess" : "PrivateAccess"
    }
  ])
}

# Encryption policy - Based on working configuration
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${substr(var.collection_name, 0, 20)}-enc"
  type = "encryption"

  policy = var.encryption_key_type == "AWS_OWNED_KMS_KEY" ? jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  }) : jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ]
        ResourceType = "collection"
        KmsARN       = var.kms_key_id
      }
    ]
  })
}