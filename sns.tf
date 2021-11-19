resource "aws_sns_topic" "pipeline_notify" {
  name = "pipeline-notify"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.pipeline_notify.arn
  protocol  = "email"
  endpoint  = "me@andrewkreuzer.com"
}
