locals {
  enabled = module.this.enabled

  bucket_enabled   = local.enabled && var.bucket_enabled
  dynamodb_enabled = local.enabled && var.dynamodb_enabled

  dynamodb_table_name = local.dynamodb_enabled ? coalesce(var.dynamodb_table_name, module.dynamodb_table_label.id) : ""

  prevent_unencrypted_uploads = local.enabled && var.prevent_unencrypted_uploads

  policy = local.prevent_unencrypted_uploads ? join(
    "",
    data.aws_iam_policy_document.prevent_unencrypted_uploads.*.json
  ) : ""

  terraform_backend_config_file = format(
    "%s/%s",
    var.terraform_backend_config_file_path,
    var.terraform_backend_config_file_name
  )

  terraform_backend_config_template_file = var.terraform_backend_config_template_file != "" ? var.terraform_backend_config_template_file : "${path.module}/templates/terraform.tf.tpl"

  terraform_backend_config_content = templatefile(local.terraform_backend_config_template_file, {
    region = data.aws_region.current.name
    # Template file inputs cannot be null, so we use empty string if the variable is null
    bucket = try(aws_s3_bucket.default[0].id, "")

    dynamodb_table = try(aws_dynamodb_table.with_server_side_encryption[0].name, "")

    encrypt              = "true"
    role_arn             = var.role_arn == null ? "" : var.role_arn
    profile              = var.profile == null ? "" : var.profile
    terraform_version    = var.terraform_version == null ? "" : var.terraform_version
    terraform_state_file = var.terraform_state_file == null ? "" : var.terraform_state_file
    namespace            = var.namespace == null ? "" : var.namespace
    stage                = var.stage == null ? "" : var.stage
    environment          = var.environment == null ? "" : var.environment
    name                 = var.name == null ? "" : var.name
  })

  labels_enabled = local.enabled && (var.s3_bucket_name == "" || var.s3_bucket_name == null)

  bucket_name = local.labels_enabled ? module.bucket_label.id : var.s3_bucket_name
}

module "bucket_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled         = local.labels_enabled
  id_length_limit = 63

  context = module.this.context
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "prevent_unencrypted_uploads" {
  count = local.prevent_unencrypted_uploads ? 1 : 0

  statement {
    sid = "DenyIncorrectEncryptionHeader"

    effect = "Deny"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${var.arn_format}:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "AES256",
        "aws:kms"
      ]
    }
  }

  statement {
    sid = "DenyUnEncryptedObjectUploads"

    effect = "Deny"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${var.arn_format}:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "true"
      ]
    }
  }

  statement {
    sid = "EnforceTlsRequestsOnly"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      "${var.arn_format}:s3:::${local.bucket_name}",
      "${var.arn_format}:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket" "default" {
  count = local.bucket_enabled ? 1 : 0

  #bridgecrew:skip=BC_AWS_S3_13:Skipping `Enable S3 Bucket Logging` check until Bridgecrew will support dynamic blocks (https://github.com/bridgecrewio/checkov/issues/776).
  #bridgecrew:skip=CKV_AWS_52:Skipping `Ensure S3 bucket has MFA delete enabled` check due to issues operating with `mfa_delete` in terraform
  bucket        = substr(local.bucket_name, 0, 63)
  force_destroy = var.force_destroy

  tags = module.this.tags
}

resource "aws_s3_bucket_policy" "default" {
  count = local.bucket_enabled ? 1 : 0

  bucket = one(aws_s3_bucket.default.*.id)
  policy = local.policy
}

resource "aws_s3_bucket_acl" "default" {
  count = local.bucket_enabled && !var.bucket_ownership_enforced_enabled ? 1 : 0

  bucket = one(aws_s3_bucket.default.*.id)
  acl    = var.acl

  # Default "bucket ownership controls" for new S3 buckets is "BucketOwnerEnforced", which disables ACLs.
  # So, we need to wait until we change bucket ownership to "BucketOwnerPreferred" before we can set ACLs.
  depends_on = [aws_s3_bucket_ownership_controls.default]
}

resource "aws_s3_bucket_versioning" "default" {
  count = local.bucket_enabled ? 1 : 0

  bucket = one(aws_s3_bucket.default.*.id)

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count = local.bucket_enabled ? 1 : 0

  bucket = one(aws_s3_bucket.default.*.id)

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "default" {
  count = local.bucket_enabled && length(var.logging) > 0 ? 1 : 0

  bucket = one(aws_s3_bucket.default.*.id)

  target_bucket = var.logging[0].target_bucket
  target_prefix = var.logging[0].target_prefix
}

resource "aws_s3_bucket_public_access_block" "default" {
  count = local.bucket_enabled && var.enable_public_access_block ? 1 : 0

  bucket                  = one(aws_s3_bucket.default.*.id)
  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}

# After you apply the bucket owner enforced setting for Object Ownership, ACLs are disabled for the bucket.
# See https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
resource "aws_s3_bucket_ownership_controls" "default" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = one(aws_s3_bucket.default.*.id)

  rule {
    object_ownership = var.bucket_ownership_enforced_enabled ? "BucketOwnerEnforced" : "BucketOwnerPreferred"
  }
}

module "dynamodb_table_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["lock"]
  context    = module.this.context
  enabled    = local.dynamodb_enabled
}

resource "aws_dynamodb_table" "with_server_side_encryption" {
  count          = local.dynamodb_enabled ? 1 : 0
  name           = local.dynamodb_table_name
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  hash_key = "LockID"

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = module.dynamodb_table_label.tags
}

resource "local_file" "terraform_backend_config" {
  count           = local.enabled && var.terraform_backend_config_file_path != "" ? 1 : 0
  content         = local.terraform_backend_config_content
  filename        = local.terraform_backend_config_file
  file_permission = "0644"
}
