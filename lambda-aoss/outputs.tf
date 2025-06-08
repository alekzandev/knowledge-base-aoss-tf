output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.aoss_query_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.aoss_query_lambda.arn
}

output "lambda_log_group_arn" {
  description = "ARN of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.log_group_lambda.arn
}