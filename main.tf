locals {
  prevent_unencrypted_uploads = var.prevent_unencrypted_uploads && var.enable_server_side_encryption ? true : false

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

  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : module.this.id
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

resource "aws_s3_bucket" "default" {
  bucket        = substr(local.bucket_name, 0, 63)
  acl           = var.acl
  force_destroy = var.force_destroy
  policy        = local.policy

  versioning {
    enabled    = true
    mfa_delete = var.mfa_delete
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  dynamic "replication_configuration" {
    for_each = var.s3_replication_enabled ? toset([var.s3_replica_bucket_arn]) : []
    content {
      role = aws_iam_role.replication[0].arn

      rules {
        id     = module.this.id
        prefix = ""
        status = "Enabled"

        destination {
          bucket        = var.s3_replica_bucket_arn
          storage_class = "STANDARD"
        }
      }
    }
  }

  tags = module.this.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  count                   = var.enable_public_access_block ? 1 : 0
  bucket                  = aws_s3_bucket.default.id
  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}

module "dynamodb_table_label" {
  source     = "cloudposse/label/null"
  version    = "0.22.0"
  attributes = compact(concat(var.attributes, ["lock"]))
  context    = module.this.context
}

resource "aws_dynamodb_table" "with_server_side_encryption" {
  count          = var.enable_server_side_encryption ? 1 : 0
  name           = module.dynamodb_table_label.id
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

  lifecycle {
    ignore_changes = [
      billing_mode,
      read_capacity,
      write_capacity,
    ]
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = module.dynamodb_table_label.tags
}

resource "aws_dynamodb_table" "without_server_side_encryption" {
  count          = var.enable_server_side_encryption ? 0 : 1
  name           = module.dynamodb_table_label.id
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  hash_key = "LockID"

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  lifecycle {
    ignore_changes = [
      billing_mode,
      read_capacity,
      write_capacity,
    ]
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = module.dynamodb_table_label.tags
}

data "aws_region" "current" {}

data "template_file" "terraform_backend_config" {
  template = file(local.terraform_backend_config_template_file)

  vars = {
    region = data.aws_region.current.name
    bucket = aws_s3_bucket.default.id

    dynamodb_table = element(
      coalescelist(
        aws_dynamodb_table.with_server_side_encryption.*.name,
        aws_dynamodb_table.without_server_side_encryption.*.name
      ),
      0
    )

    encrypt              = var.enable_server_side_encryption ? "true" : "false"
    role_arn             = var.role_arn
    profile              = var.profile
    terraform_version    = var.terraform_version
    terraform_state_file = var.terraform_state_file
    namespace            = var.namespace
    stage                = var.stage
    environment          = var.environment
    name                 = var.name
  }
}

resource "local_file" "terraform_backend_config" {
  count           = var.terraform_backend_config_file_path != "" ? 1 : 0
  content         = data.template_file.terraform_backend_config.rendered
  filename        = local.terraform_backend_config_file
  file_permission = "0644"
}
