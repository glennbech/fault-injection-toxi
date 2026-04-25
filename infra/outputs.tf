output "lambda_function_url" {
  description = "Lambda Function URL endpoint - use this in the webapp"
  value       = aws_lambda_function_url.order_processor_url.function_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.order_processor.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for orders"
  value       = aws_dynamodb_table.orders.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.orders.arn
}

output "student_id" {
  description = "Student identifier used for this deployment"
  value       = var.student_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "instructions" {
  description = "Next steps"
  value       = <<-EOT

  Deployment complete!

  1. Copy the Lambda Function URL above
  2. Open webapp/src/config.js and update LAMBDA_URL with this value
  3. Run 'npm run dev' in the webapp directory
  4. Open the app in your browser and test the checkout

  View Lambda logs:
    aws logs tail ${aws_cloudwatch_log_group.lambda_logs.name} --follow

  View DynamoDB items:
    aws dynamodb scan --table-name ${aws_dynamodb_table.orders.name}
  EOT
}
