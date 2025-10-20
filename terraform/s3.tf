resource "aws_s3_bucket" "reports" {
  bucket        = "levelup-reports-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket" "logs" {
  bucket        = "levelup-logs-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket" "ai_summaries" {
  bucket        = "levelup-ai-summaries-${var.environment}"
  force_destroy = true
}
