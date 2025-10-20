resource "aws_sns_topic" "ai_summaries_topic" {
  name = "ai-summaries-${var.environment}"
}
