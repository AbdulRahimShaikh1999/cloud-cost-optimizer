# resource "aws_cloudwatch_dashboard" "main" {
#   dashboard_name = "cost-optimizer-${var.environment}"
#   dashboard_body = jsonencode({
#     widgets = []
#   })
# }

############################################
# Log groups (explicit retention)
############################################
resource "aws_cloudwatch_log_group" "scanner" {
  name              = "/aws/lambda/scanner-lambda-${var.environment}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "action" {
  name              = "/aws/lambda/action-lambda-${var.environment}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ai_insights" {
  name              = "/aws/lambda/ai-insights-lambda-${var.environment}"
  retention_in_days = 14
}

############################################
# Alarms — Lambda errors (one per function)
############################################
resource "aws_cloudwatch_metric_alarm" "errors_scanner" {
  alarm_name          = "scanner-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when scanner lambda reports any errors"
  dimensions = {
    FunctionName = "scanner-lambda-${var.environment}"
  }
  alarm_actions = [aws_sns_topic.ai_summaries_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "errors_action" {
  alarm_name          = "action-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when action lambda reports any errors"
  dimensions = {
    FunctionName = "action-lambda-${var.environment}"
  }
  alarm_actions = [aws_sns_topic.ai_summaries_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "errors_ai" {
  alarm_name          = "ai-insights-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when ai-insights lambda reports any errors"
  dimensions = {
    FunctionName = "ai-insights-lambda-${var.environment}"
  }
  alarm_actions = [aws_sns_topic.ai_summaries_topic.arn]
}

############################################
# Alarm — Custom metric: IdleEC2Count >= 5
############################################
resource "aws_cloudwatch_metric_alarm" "idle_ec2_high" {
  alarm_name          = "idle-ec2-high-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IdleEC2Count"
  namespace           = "CloudCostOptimizer"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when a scan detects >=5 idle EC2 instances"
  dimensions = {
    Environment = var.environment
  }
  alarm_actions = [aws_sns_topic.ai_summaries_topic.arn]
}

############################################
# Dashboard — key widgets
############################################
resource "aws_cloudwatch_dashboard" "cost_optimizer" {
  dashboard_name = "cloud-cost-optimizer-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type": "metric",
        "x": 0, "y": 0, "width": 12, "height": 6,
        "properties": {
          "title": "Lambda Invocations (5m)",
          "region": var.aws_region,
          "view": "timeSeries",
          "stacked": false,
          "metrics": [
            [ "AWS/Lambda", "Invocations", "FunctionName", "scanner-lambda-${var.environment}", { "stat": "Sum" } ],
            [ ".", "Invocations", "FunctionName", "action-lambda-${var.environment}", { "stat": "Sum" } ],
            [ ".", "Invocations", "FunctionName", "ai-insights-lambda-${var.environment}", { "stat": "Sum" } ]
          ],
          "period": 300
        }
      },
      {
        "type": "metric",
        "x": 12, "y": 0, "width": 12, "height": 6,
        "properties": {
          "title": "Lambda Errors (5m)",
          "region": var.aws_region,
          "view": "timeSeries",
          "stacked": false,
          "metrics": [
            [ "AWS/Lambda", "Errors", "FunctionName", "scanner-lambda-${var.environment}", { "stat": "Sum" } ],
            [ ".", "Errors", "FunctionName", "action-lambda-${var.environment}", { "stat": "Sum" } ],
            [ ".", "Errors", "FunctionName", "ai-insights-lambda-${var.environment}", { "stat": "Sum" } ]
          ],
          "period": 300
        }
      },
      {
        "type": "metric",
        "x": 0, "y": 6, "width": 12, "height": 6,
        "properties": {
          "title": "Lambda Duration (avg, ms)",
          "region": var.aws_region,
          "view": "timeSeries",
          "stacked": false,
          "metrics": [
            [ "AWS/Lambda", "Duration", "FunctionName", "scanner-lambda-${var.environment}", { "stat": "Average" } ],
            [ ".", "Duration", "FunctionName", "action-lambda-${var.environment}", { "stat": "Average" } ],
            [ ".", "Duration", "FunctionName", "ai-insights-lambda-${var.environment}", { "stat": "Average" } ]
          ],
          "period": 300
        }
      },
      {
        "type": "metric",
        "x": 12, "y": 6, "width": 12, "height": 6,
        "properties": {
          "title": "IdleEC2Count (from Scanner)",
          "region": var.aws_region,
          "view": "timeSeries",
          "stacked": false,
          "metrics": [
            [ "CloudCostOptimizer", "IdleEC2Count", "Environment", "${var.environment}", { "stat": "Sum" } ]
          ],
          "period": 300
        }
      }
    ]
  })
}
