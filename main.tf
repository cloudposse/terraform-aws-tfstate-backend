
locals {
  enabled           = module.this.enabled
  blue_region       = one(data.aws_region.blue[*].name)
  green_region      = one(data.aws_region.green[*].name)
  blue_kms_key_arn  = length(var.blue_kms_key_arn) == 0 ? one(data.aws_kms_alias.blue[*].arn) : one(var.blue_kms_key_arn[*])
  green_kms_key_arn = length(var.green_kms_key_arn) == 0 ? one(data.aws_kms_alias.green[*].arn) : one(var.green_kms_key_arn[*])

  blue_backend_config = !local.enabled || try(module.blue_bucket[0].bucket, null) == null ? null : merge({
    encrypt = true
    key     = "terraform.tfstate"
    region  = module.blue_bucket[0].bucket.region
    },
    var.replication_enabled ? {
      bucket           = "multi-region"
      endpoint         = module.blue_bucket[0].bucket.bucket_regional_domain_name
      force_path_style = true } : {
      bucket           = module.blue_bucket[0].bucket.id
    },
    var.lock_table_enabled ? {
      dynamodb_table = one(aws_dynamodb_table.locks[*].id)
  } : {})

  green_backend_config = !local.replication_enabled || try(module.green_bucket[0].bucket, null) == null ? null : merge({
    encrypt = true
    key     = "terraform.tfstate"
    region  = module.green_bucket[0].bucket.region
    },
    var.replication_enabled ? {
      bucket           = "multi-region"
      endpoint         = module.green_bucket[0].bucket.bucket_regional_domain_name
      force_path_style = true } : {
      bucket           = module.green_bucket[0].bucket.id
    },
    var.lock_table_enabled ? {
      dynamodb_table = one(aws_dynamodb_table.locks[*].id)
  } : {})

}

data "aws_region" "blue" {
  count = local.enabled ? 1 : 0

  provider = aws.blue
}

data "aws_region" "green" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.green

  lifecycle {
    postcondition {
      condition     = self.name != local.blue_region
      error_message = format("If replication is enabled, aws.blue and aws.green providers must reference different AWS regions. Both are %s", local.blue_region)
    }
  }
}


data "aws_kms_alias" "blue" {
  count = local.enabled && length(var.blue_kms_key_arn) == 0 ? 1 : 0

  provider = aws.blue
  name     = "alias/aws/s3"
}

data "aws_kms_alias" "green" {
  count = local.enabled && length(var.green_kms_key_arn) == 0 ? 1 : 0

  provider = aws.green
  name     = "alias/aws/s3"
}

