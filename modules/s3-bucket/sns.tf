
locals {
  topic_name = "${var.bucket_name}-replication"
}

data "aws_iam_policy_document" "topic" {
  count = var.sns_enabled ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:${local.topic_name}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.each.arn]
    }
  }
}
resource "aws_sns_topic" "replication" {
  count = var.sns_enabled ? 1 : 0

  name   = local.topic_name
  policy = one(data.aws_iam_policy_document.topic[*].json)

  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.sns_enabled ? 1 : 0

  bucket = aws_s3_bucket.each.id

  topic {
    id        = local.topic_name
    topic_arn = one(aws_sns_topic.replication[*].arn)
    events    = ["s3:Replication:*"]
  }
}
