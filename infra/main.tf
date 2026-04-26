terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# DynamoDB table for storing orders
resource "aws_dynamodb_table" "orders" {
  name         = "chaos-coffee-${var.student_id}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = {
    Name      = "chaos-coffee-${var.student_id}"
    Student   = var.student_id
    Project   = "chaos-engineering-lab"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "chaos-coffee-lambda-${var.student_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "chaos-coffee-lambda-${var.student_id}"
    Student = var.student_id
    Project = "chaos-engineering-lab"
  }
}

# IAM policy for DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.orders.arn
      }
    ]
  })
}

# Attach AWS managed policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda function
resource "aws_lambda_function" "order_processor" {
  filename      = "${path.module}/../lambda/function.zip"
  function_name = "chaos-coffee-${var.student_id}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"

  source_code_hash = filebase64sha256("${path.module}/../lambda/function.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.orders.name
      STUDENT_ID = var.student_id
    }
  }

  timeout     = 5
  memory_size = 128

  tags = {
    Name    = "chaos-coffee-${var.student_id}"
    Student = var.student_id
    Project = "chaos-engineering-lab"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.order_processor.function_name}"
  retention_in_days = 7

  tags = {
    Name    = "chaos-coffee-logs-${var.student_id}"
    Student = var.student_id
    Project = "chaos-engineering-lab"
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "order_processor_url" {
  function_name      = aws_lambda_function.order_processor.function_name
  authorization_type = "NONE"

  # NOTE: Intentionally NO CORS configuration here
  # This is part of the chaos engineering exercise
  # Students will encounter CORS errors and learn how to handle them
}
