resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.bucket
  policy = data.aws_iam_policy_document.main.json
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.encryption == null ? 0 : 1
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption.sse_algorithm
      kms_master_key_id = var.encryption.kms_master_key_id
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count                   = var.block_public_access ? 1 : 0
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id

  topic {
    topic_arn     = aws_sns_topic.s3_notification.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json.gz"
  }

#  topic {
#    topic_arn     = aws_sns_topic.s3_notification.arn
#    events        = ["s3:ObjectCreated:*"]
#    filter_suffix = ".csv.gz"
#  }

  topic {
    topic_arn     = aws_sns_topic.s3_notification.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = "Manifest.json"
  }

  depends_on = [
    aws_sns_topic_policy.s3_notification,
    aws_s3_bucket_policy.main
  ]
}

data "aws_iam_policy_document" "main" {
  statement {
    sid = "LogsACLCheck"
    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
      "s3:GetBucketPolicy"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.main.bucket}"]

    principals {
      type        = "Service"
      identifiers = local.service_principals
    }

#    principals {
#      type        = "AWS"
#      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#    }
  }

#  statement {
#    sid = "ReadOwnLogs"
#
#    actions = [
#      "s3:Get*",
#      "s3:List*",
#    ]
#
#    resources = [
#      "arn:aws:s3:::${aws_s3_bucket.main.bucket}",
#      "arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"
#    ]
#
#    principals {
#      type        = "AWS"
#      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#    }
#  }

  statement {
    sid       = "WriteLogs"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"]

    principals {
      type        = "Service"
      identifiers = local.service_principals
    }

#    condition {
#      test     = "StringEquals"
#      variable = "s3:x-amz-acl"
#      values   = ["bucket-owner-full-control"]
#    }
  }
}

resource "aws_sns_topic" "s3_notification" {
  name = var.notification_topic_name
}

resource "aws_sns_topic_policy" "s3_notification" {
  arn    = aws_sns_topic.s3_notification.arn
  policy = data.aws_iam_policy_document.sns_notification.json
}

data "aws_iam_policy_document" "sns_notification" {
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [data.aws_caller_identity.current.account_id]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [aws_sns_topic.s3_notification.arn]

    sid = "__default_statement_ID"
  }

  statement {
    sid = "PublishNotificationsFromS3"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.s3_notification.arn]
  }
}