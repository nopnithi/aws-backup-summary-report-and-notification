# SNS topic for send notification via email
resource "aws_sns_topic" "backup_notification" {
  name   = var.topic_name
  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:${var.region}:${var.account_id}:${var.topic_name}",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.backup_notification.arn}"}
        }
    }]
}
EOF
}

# Create topic subscriptions with a list of email
resource "aws_sns_topic_subscription" "backup_notification" {
  for_each = toset(var.emails)

  topic_arn = aws_sns_topic.backup_notification.arn
  protocol  = "email"
  endpoint  = each.key
}
