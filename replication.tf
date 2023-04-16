# Create an IAM role that allows cross-account replication

locals {
  bucket_arns           = compact([one(module.blue_bucket[*].bucket.arn), one(module.green_bucket[*].bucket.arn)])
  replication_enabled   = local.enabled && var.replication_enabled
  replication_role_name = length(var.replication_role_name) > 0 ? var.replication_role_name[0] : module.replication_label.id
}

data "aws_iam_policy_document" "replication_assume_role" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid     = "AWSReplicationRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com",
        "batchoperations.s3.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "replication" {
  count = local.replication_enabled ? 1 : 0

  name                 = module.replication_label.id
  assume_role_policy   = one(data.aws_iam_policy_document.replication_assume_role[*].json)
  tags                 = module.replication_label.tags
  permissions_boundary = one(var.permissions_boundary[*])
}

data "aws_iam_policy_document" "replication" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid    = "GetObjectsToReplicate"
    effect = "Allow"

    resources = concat(local.bucket_arns, formatlist("%s/*", local.bucket_arns))

    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold",
    ]
  }

  statement {
    sid    = "ReplicateObjects"
    effect = "Allow"

    resources = formatlist("%s/*", local.bucket_arns)

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
  }

  # Allow the role to use the KMS key to encrypt/decrypt objects in both buckets
  statement {
    sid       = "DecryptBlueObjects"
    effect    = "Allow"
    resources = [local.blue_kms_key_arn]
    actions   = ["kms:Decrypt"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.blue_region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [format("%s/*", one(module.blue_bucket[*].bucket.arn))]
    }
  }

  statement {
    sid       = "DecryptGreenObjects"
    effect    = "Allow"
    resources = [local.green_kms_key_arn]
    actions   = ["kms:Decrypt"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.green_region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [format("%s/*", one(module.green_bucket[*].bucket.arn))]
    }
  }


  statement {
    sid       = "EncryptBlueObjects"
    effect    = "Allow"
    resources = [local.blue_kms_key_arn]
    actions   = ["kms:Encrypt"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.blue_region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [format("%s/*", one(module.blue_bucket[*].bucket.arn))]
    }
  }

  statement {
    sid       = "EncryptGreenObjects"
    effect    = "Allow"
    resources = [local.green_kms_key_arn]
    actions   = ["kms:Encrypt"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.green_region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [format("%s/*", one(module.green_bucket[*].bucket.arn))]
    }
  }
}

resource "aws_iam_policy" "replication" {
  count = local.replication_enabled ? 1 : 0

  name        = module.replication_label.id
  description = "S3 bucket replication policy"
  policy      = one(data.aws_iam_policy_document.replication[*].json)
  tags        = module.replication_label.tags
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  count = local.replication_enabled ? 1 : 0

  role       = one(aws_iam_role.replication[*].name)
  policy_arn = one(aws_iam_policy.replication[*].arn)
}
