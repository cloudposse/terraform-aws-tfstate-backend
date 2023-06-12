locals {
  enabled = module.this.enabled

  bucket_enabled   = local.enabled && var.bucket_enabled
  dynamodb_enabled = local.enabled && var.dynamodb_enabled

  dynamodb_table_name = local.dynamodb_enabled ? coalesce(var.dynamodb_table_name, module.dynamodb_table_label.id) : ""

  prevent_unencrypted_uploads = local.enabled && var.prevent_unencrypted_uploads && var.enable_server_side_encryption

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
    bucket = join("", aws_s3_bucket.default.*.id)

    dynamodb_table = local.dynamodb_enabled ? element(
      coalescelist(
        aws_dynamodb_table.with_server_side_encryption.*.name,
        aws_dynamodb_table.without_server_side_encryption.*.name
      ),
      0
    ) : ""

    encrypt              = var.enable_server_side_encryption ? "true" : "false"
    role_arn             = var.role_arn
    profile              = var.profile
    terraform_version    = var.terraform_version
    terraform_state_file = var.terraform_state_file
    namespace            = var.namespace
    stage                = var.stage
    environment          = var.environment
    name                 = var.name
  })

  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : module.this.id

  logging_bucket_enabled      = local.bucket_enabled && var.logging_bucket_enabled
  logging_bucket_name_default = try(var.logging["bucket_name"], "${local.bucket_name}-logs")
  logging_prefix_default      = try(var.logging["prefix"], "logs/")
  logging_bucket_name         = local.logging_bucket_enabled ? module.log_storage.bucket_id : local.logging_bucket_name_default
  logging_prefix              = local.logging_bucket_enabled ? module.log_storage.prefix : local.logging_prefix_default
}

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

module "log_storage" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.4.1"

  enabled                  = local.logging_bucket_enabled
  access_log_bucket_prefix = local.logging_prefix_default
  acl                      = "log-delivery-write"
  expiration_days          = var.logging_bucket_expiration_days
  glacier_transition_days  = var.logging_bucket_glacier_transition_days
  name                     = local.logging_bucket_name_default
  standard_transition_days = var.logging_bucket_standard_transition_days

  context = module.this.context
}

resource "aws_s3_bucket" "default" {
  count = local.bucket_enabled ? 1 : 0

  #bridgecrew:skip=BC_AWS_S3_13:Skipping `Enable S3 Bucket Logging` check until Bridgecrew will support dynamic blocks (https://github.com/bridgecrewio/checkov/issues/776).
  #bridgecrew:skip=CKV_AWS_52:Skipping `Ensure S3 bucket has MFA delete enabled` check due to issues operating with `mfa_delete` in terraform
  #bridgecrew:skip=BC_AWS_NETWORKING_52: Skipping `Ensure S3 Bucket has public access blocks` because we have chosen to make it configurable
  #bridgecrew:skip=BC_AWS_S3_16:Skipping `Ensure AWS S3 object versioning is enabled` because we have it enabled, but Bridgecrew doesn't recognize it
  bucket        = substr(local.bucket_name, 0, 63)
  force_destroy = var.force_destroy

  tags = module.this.tags
}

resource "aws_s3_bucket_acl" "default" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  acl = var.acl

  depends_on = [aws_s3_bucket_ownership_controls.default]
}

# Per https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
resource "aws_s3_bucket_ownership_controls" "default" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "default" {
  count      = local.bucket_enabled ? 1 : 0
  bucket     = join("", aws_s3_bucket.default.*.id)
  policy     = local.policy
  depends_on = [aws_s3_bucket_public_access_block.default]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "default" {
  count  = local.bucket_enabled ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_logging" "default" {
  count  = local.bucket_enabled && var.logging != null ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  target_bucket = local.logging_bucket_name
  target_prefix = local.logging_prefix
}


resource "aws_s3_bucket_public_access_block" "default" {
  count                   = local.bucket_enabled && var.enable_public_access_block ? 1 : 0
  bucket                  = join("", aws_s3_bucket.default.*.id)
  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_replication_configuration" "default" {
  count = local.bucket_enabled && var.s3_replication_enabled ? 1 : 0

  bucket = join("", aws_s3_bucket.default.*.id)
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = module.this.id
    status = "Enabled"

    destination {
      # Prefer newer system of specifying bucket in rule, but maintain backward compatibility with
      # s3_replica_bucket_arn to specify single destination for all rules
      bucket        = var.s3_replica_bucket_arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    # versioning must be set before replication
    aws_s3_bucket_versioning.default
  ]
}


module "dynamodb_table_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["lock"]
  context    = module.this.context
  enabled    = local.dynamodb_enabled
}

resource "aws_dynamodb_table" "with_server_side_encryption" {
  #bridgecrew:skip=BC_AWS_GENERAL_44:Skipping `Ensure DynamoDB Tables have Auto Scaling enabled` because we know this is low usage
  count          = local.dynamodb_enabled && var.enable_server_side_encryption ? 1 : 0
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

resource "aws_dynamodb_table" "without_server_side_encryption" {
  #bridgecrew:skip=BC_AWS_GENERAL_44:Skipping `Ensure DynamoDB Tables have Auto Scaling enabled` because we know this is low usage
  count          = local.dynamodb_enabled && !var.enable_server_side_encryption ? 1 : 0
  name           = local.dynamodb_table_name
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  hash_key = "LockID"

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = module.dynamodb_table_label.tags
}

data "aws_region" "current" {}

resource "local_file" "terraform_backend_config" {
  count           = local.enabled && var.terraform_backend_config_file_path != "" ? 1 : 0
  content         = local.terraform_backend_config_content
  filename        = local.terraform_backend_config_file
  file_permission = "0644"
}
