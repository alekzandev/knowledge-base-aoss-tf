# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "log_group_lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(local.common_tags, {
    Name = "${var.lambda_function_name}-logs"
  })
}