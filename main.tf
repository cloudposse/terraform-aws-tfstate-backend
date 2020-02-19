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
}

module "base_label" {
  source              = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.13.0"
  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  name                = var.name
  delimiter           = var.delimiter
  attributes          = var.attributes
  tags                = var.tags
  additional_tag_map  = var.additional_tag_map
  context             = var.context
  label_order         = var.label_order
  regex_replace_chars = var.regex_replace_chars
}

module "s3_bucket_label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.13.0"
  context = module.base_label.context
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
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${module.s3_bucket_label.id}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "AES256",
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
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${module.s3_bucket_label.id}/*",
    ]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "true",
      ]
    }
  }
}

resource "aws_s3_bucket" "default" {
  bucket        = module.s3_bucket_label.id
  acl           = var.acl
  region        = var.region
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

  tags = module.s3_bucket_label.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.default.id
  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}

module "dynamodb_table_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.13.0"
  context    = module.base_label.context
  attributes = compact(concat(var.attributes, ["lock"]))
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

data "template_file" "terraform_backend_config" {
  template = file("${path.module}/templates/terraform.tf.tpl")

  vars = {
    region = var.region
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
  }
}

resource "local_file" "terraform_backend_config" {
  count    = var.terraform_backend_config_file_path != "" ? 1 : 0
  content  = data.template_file.terraform_backend_config.rendered
  filename = local.terraform_backend_config_file
}
