locals {
  enabled = module.this.enabled

  bucket_enabled   = local.enabled && var.bucket_enabled
  dynamodb_enabled = local.enabled && var.dynamodb_enabled

  dynamodb_table_name = local.dynamodb_enabled ? coalesce(var.dynamodb_table_name, module.dynamodb_table_label.id) : ""

  prevent_unencrypted_uploads = local.enabled && var.prevent_unencrypted_uploads && var.enable_server_side_encryption

  terraform_backend_config_file = format(
    "%s/%s",
    var.terraform_backend_config_file_path,
    var.terraform_backend_config_file_name
  )

  terraform_backend_config_template_file = var.terraform_backend_config_template_file != "" ? var.terraform_backend_config_template_file : "${path.module}/templates/terraform.tf.tpl"

  terraform_backend_config_content = templatefile(local.terraform_backend_config_template_file, {
    region = data.aws_region.current.name
    bucket = module.tfstate_s3_bucket.bucket_id

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

module "log_storage" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "0.28.0"

  enabled                  = local.logging_bucket_enabled
  access_log_bucket_prefix = local.logging_prefix_default
  acl                      = "log-delivery-write"
  expiration_days          = var.logging_bucket_expiration_days
  glacier_transition_days  = var.logging_bucket_glacier_transition_days
  name                     = local.logging_bucket_name_default
  standard_transition_days = var.logging_bucket_standard_transition_days

  context = module.this.context
}

module "tfstate_s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "0.49.0"

  enabled            = local.bucket_enabled
  bucket_name        = local.bucket_name
  acl                = var.acl
  force_destroy      = var.force_destroy
  versioning_enabled = true
  sse_algorithm      = "AES256"

  #bridgecrew:skip=CKV_AWS_52:Skipping `Ensure S3 bucket has MFA delete enabled` due to issue in terraform (https://github.com/hashicorp/terraform-provider-aws/issues/629).
  #mfa_delete = var.mfa_delete

  allow_encrypted_uploads_only = local.prevent_unencrypted_uploads
  allow_ssl_requests_only      = local.prevent_unencrypted_uploads

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  s3_replication_enabled = var.s3_replication_enabled
  s3_replica_bucket_arn  = var.s3_replica_bucket_arn

  logging = var.logging == null ? null : {
    bucket_name = local.logging_bucket_name
    prefix      = local.logging_prefix
  }

  context = module.this.context
}

module "dynamodb_table_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["lock"]
  context    = module.this.context
  enabled    = local.dynamodb_enabled
}

resource "aws_dynamodb_table" "with_server_side_encryption" {
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
