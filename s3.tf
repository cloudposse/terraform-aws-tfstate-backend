# Using Terraform, create 2 S3 buckets in different regions with bi-directional cross-region replication

locals {
  colors = local.enabled ? (var.replication_enabled ? toset(["blue", "green"]) : toset(["blue"])) : toset([])
  other_color = {
    blue  = "green"
    green = "blue"
  }
  s3_regions = {
    blue  = local.blue_region
    green = local.green_region
  }
  s3_bucket_names = {
    blue  = length(var.blue_s3_bucket_name) > 0 ? var.blue_s3_bucket_name[0] : module.blue_label.id
    green = length(var.green_s3_bucket_name) > 0 ? var.green_s3_bucket_name[0] : module.green_label.id
  }
  s3_buckets = {
    // If a bucket was destroyed outside of Terraform and then you run `terraform destroy`,
    // and you had replication enabled, module.blue_bucket[0] would exist but not have a `bucket`.
    blue  = try(one(module.blue_bucket[*].bucket), null)
    green = try(one(module.green_bucket[*].bucket), null)
  }
}

# Create the S3 buckets
# This would be a whole lot easier if Terraform supported dynamic providers,
# but it doesn't, so we have to instantiate the module twice.

module "blue_bucket" {
  count  = local.enabled ? 1 : 0
  source = "./modules/s3-bucket"

  providers = {
    aws = aws.blue
  }
  bucket_name = local.s3_bucket_names["blue"]
  # In order to ensure that replication has access to the KMS key,
  # we explicitly set the key when replication is enabled.
  # Otherwise, we use the default KMS key (S3-SSE).
  kms_key_arn    = local.replication_enabled ? [local.blue_kms_key_arn] : var.blue_kms_key_arn
  tags           = module.blue_label.tags
  bucket_logging = var.blue_bucket_logging
  sns_enabled    = local.replication_enabled
  force_destroy  = var.force_destroy
}

module "green_bucket" {
  count  = local.replication_enabled ? 1 : 0
  source = "./modules/s3-bucket"

  providers = {
    aws = aws.green
  }
  bucket_name    = local.s3_bucket_names["green"]
  kms_key_arn    = [local.green_kms_key_arn]
  tags           = module.green_label.tags
  bucket_logging = var.green_bucket_logging
  force_destroy  = var.force_destroy
}


# Configure the replication rules

resource "aws_s3_bucket_replication_configuration" "blue" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.blue

  bucket = one(module.blue_bucket[*].bucket.id)
  role   = one(aws_iam_role.replication[*].arn)

  rule {
    id = "blue-to-green"

    status = "Enabled"
    filter {}

    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = one(module.green_bucket[*].bucket.arn)
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = local.green_kms_key_arn
      }

      metrics {
        event_threshold {
          minutes = 15
        }
        status = "Enabled"
      }

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }

  # Must have bucket versioning enabled first
  depends_on = [module.blue_bucket, module.green_bucket]
}


resource "aws_s3_bucket_replication_configuration" "green" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.green

  bucket = one(module.green_bucket[*].bucket.id)
  role   = one(aws_iam_role.replication[*].arn)

  rule {
    id = "green-to-blue"

    status = "Enabled"
    filter {}

    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = one(module.blue_bucket[*].bucket.arn)
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = local.blue_kms_key_arn
      }

      metrics {
        event_threshold {
          minutes = 15
        }
        status = "Enabled"
      }

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }

  # Must have bucket versioning enabled first
  depends_on = [module.blue_bucket, module.green_bucket]
}


