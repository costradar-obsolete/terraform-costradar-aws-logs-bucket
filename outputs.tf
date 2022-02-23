output "bucket" {
  value = aws_s3_bucket.main
}

output "notification_topic" {
  value = aws_sns_topic.s3_notification
}

output notification_topic_policy {
  value = aws_sns_topic_policy.s3_notification
}

output bucket_policy {
  value = aws_s3_bucket_policy.main
}