resource "aws_lambda_function" "scanner" {
  function_name = "scanner-lambda-${var.environment}"
  package_type  = "Image"
  image_uri     = "982081047984.dkr.ecr.${var.aws_region}.amazonaws.com/scanner-lambda:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 300

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.resource_tracker.name
      S3_BUCKET = aws_s3_bucket.reports.bucket
      ENV       = var.environment
    }
  }
}

resource "aws_lambda_function" "action" {
  function_name = "action-lambda-${var.environment}"
  package_type  = "Image"
  image_uri     = "982081047984.dkr.ecr.${var.aws_region}.amazonaws.com/action-lambda:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 300

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.resource_tracker.name
      S3_BUCKET = aws_s3_bucket.reports.bucket
      ENV       = var.environment
    }
  }
}

resource "aws_lambda_function" "ai-insights" {
  function_name = "ai-insights-lambda-${var.environment}"
  package_type  = "Image"
  image_uri     = "982081047984.dkr.ecr.${var.aws_region}.amazonaws.com/ai-insights-lambda:latest"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 300

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.resource_tracker.name
      S3_BUCKET = aws_s3_bucket.reports.bucket
      ENV       = var.environment
    }
  }
}
