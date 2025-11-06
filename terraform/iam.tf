resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-exec-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_bedrock_policy" {
  name = "lambda-bedrock-policy-${var.environment}"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda-s3-access"
  role = aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::levelup-reports-staging/*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda_exec_staging_policy" {
  name = "lambda-exec-staging-policy"
  role = aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "dynamodb:*",
          "s3:*",
          "sns:Publish" 
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda_put_metric_policy" {
  name = "lambda-put-metric-${var.environment}"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:PutMetricData"],
        Resource = "*",
        Condition = {
          StringEquals = {
            "cloudwatch:namespace": "CloudCostOptimizer"
          }
        }
      }
    ]
  })
}
