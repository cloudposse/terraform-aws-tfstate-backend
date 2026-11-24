locals {
  replication_enabled     = local.enabled && var.s3_replication_enabled
  replication_kms_enabled = local.replication_enabled && var.s3_replica_kms_key_arn != null
  replication_label = local.labels_enabled ? module.replication_label.id : (
    length(local.bucket_name) <= 52 ? format("%s-replication", local.bucket_name) : (
      length(local.bucket_name) <= 59 ? format("%s-repl", local.bucket_name) : format("%s-replication", substr(local.bucket_name, 0, 52)
      )
    )
  )
}

module "replication_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled    = local.replication_enabled && local.labels_enabled
  attributes = ["replication"]

  id_length_limit = 64

  context = module.this.context
}

resource "aws_iam_role" "replication" {
  count = local.replication_enabled ? 1 : 0

  name                 = local.replication_label
  assume_role_policy   = data.aws_iam_policy_document.replication_sts[0].json
  permissions_boundary = var.permissions_boundary

  tags = module.this.tags
}

data "aws_iam_policy_document" "replication_sts" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid    = "AllowPrimaryToAssumeServiceRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "replication" {
  count = local.replication_enabled ? 1 : 0

  name   = local.replication_label
  policy = data.aws_iam_policy_document.replication[0].json
  tags   = module.this.tags
}

data "aws_iam_policy_document" "replication" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid    = "AllowGetObjectsToReplicate"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold",
      "s3:ListBucket"
    ]
    resources = [
      join("", aws_s3_bucket.default[*].arn),
      "${join("", aws_s3_bucket.default[*].arn)}/*"
    ]
  }

  statement {
    sid    = "AllowPrimaryToReplicate"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = ["${var.s3_replica_bucket_arn}/*"]
  }

  # SSE-KMS objects: decrypt the source object (any key S3 uses for this
  # bucket, including the AWS managed aws/s3 key) and encrypt the replica
  # with the destination key. Both are scoped to S3 and to the bucket through
  # the S3 encryption context (object ARN, or the bucket ARN when the bucket
  # uses an S3 Bucket Key).
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html
  dynamic "statement" {
    for_each = local.replication_kms_enabled ? [1] : []
    content {
      sid       = "AllowDecryptSourceObjects"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = ["*"]

      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.*.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values   = [join("", aws_s3_bucket.default[*].arn), "${join("", aws_s3_bucket.default[*].arn)}/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.replication_kms_enabled ? [1] : []
    content {
      sid       = "AllowEncryptReplicaObjects"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
      resources = [var.s3_replica_kms_key_arn]

      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.*.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values   = [var.s3_replica_bucket_arn, "${var.s3_replica_bucket_arn}/*"]
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = local.replication_enabled ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count = local.replication_enabled ? 1 : 0

  bucket = one(aws_s3_bucket.default[*].id)
  role   = one(aws_iam_role.replication[*].arn)

  rule {
    id = module.this.id

    status = "Enabled"
    filter {}

    delete_marker_replication {
      status = var.s3_replication_delete_marker_enabled ? "Enabled" : "Disabled"
    }

    dynamic "source_selection_criteria" {
      for_each = local.replication_kms_enabled ? [1] : []
      content {
        sse_kms_encrypted_objects {
          status = "Enabled"
        }
      }
    }

    destination {
      bucket        = var.s3_replica_bucket_arn
      storage_class = "STANDARD"

      dynamic "encryption_configuration" {
        for_each = local.replication_kms_enabled ? [1] : []
        content {
          replica_kms_key_id = var.s3_replica_kms_key_arn
        }
      }
    }
  }

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.default]
}
