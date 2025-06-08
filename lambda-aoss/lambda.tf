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

# Lambda function
resource "aws_lambda_function" "aoss_query_lambda" {
  filename         = "lambda_function.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30
  #log group = aws_cloudwatch_log_group.log_group_lambda.name



  environment {
    variables = {
      AOSS_ENDPOINT = var.aoss_endpoint
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_aoss_policy,
    aws_cloudwatch_log_group.log_group_lambda
  ]
}