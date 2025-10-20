resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "cost-optimizer-${var.environment}"
  dashboard_body = jsonencode({
    widgets = []
  })
}
