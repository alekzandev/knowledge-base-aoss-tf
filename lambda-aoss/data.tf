data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Archive Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "lambda_package"
  output_path = "lambda_function.zip"
}