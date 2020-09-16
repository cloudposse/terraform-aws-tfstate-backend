resource "aws_iam_role" "replication" {
  count = var.s3_replication_enabled ? 1 : 0

  name               = format("%s-replication", module.base_label.id)
  assume_role_policy = data.aws_iam_policy_document.replication_sts[0].json
}

data "aws_iam_policy_document" "replication_sts" {
  count = var.s3_replication_enabled ? 1 : 0

  statement {
    sid     = "AllowPrimaryToAssumeServiceRole"
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "replication" {
  count = var.s3_replication_enabled ? 1 : 0

  name   = format("%s-replication", module.base_label.id)
  policy = data.aws_iam_policy_document.replication[0].json
}

data "aws_iam_policy_document" "replication" {
  count = var.s3_replication_enabled ? 1 : 0

  statement {
    sid     = "AllowPrimaryToGetReplicationConfiguration"
    effect  = "Allow"
    actions = [
      "s3:Get*",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.default.arn,
      "${aws_s3_bucket.default.arn}/*"
    ]
  }

  statement {
    sid     = "AllowPrimaryToReplicate"
    effect  = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging"
    ]

    resources = ["${var.s3_replica_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  count = var.s3_replication_enabled ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}