# Example deployment configuration
# Copy this to a new directory and customize

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"

  # Optional: Use a specific profile
  # profile = "your-aws-profile"
}

module "chaos_coffee" {
  source = "../../infra"

  # REQUIRED: Change this to your unique identifier
  # Use lowercase letters, numbers, and hyphens only
  # Examples: "john-doe", "team-1", "alice-smith"
  student_id = "CHANGE-ME"
}

# Outputs
output "lambda_function_url" {
  description = "Use this URL in webapp/src/config.js"
  value       = module.chaos_coffee.lambda_function_url
}

output "dynamodb_table_name" {
  description = "DynamoDB table for orders"
  value       = module.chaos_coffee.dynamodb_table_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Lambda logs"
  value       = module.chaos_coffee.cloudwatch_log_group
}

output "next_steps" {
  value = module.chaos_coffee.instructions
}
