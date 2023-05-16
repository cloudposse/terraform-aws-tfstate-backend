provider "aws" {
  region = var.region
}

#S3 access controls, policies and logging should be created as seperate terraform resources
#tfsec:ignore:aws-s3-block-public-acls tfsec:ignore:aws-s3-block-public-policy tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-ignore-public-acls tfsec:ignore:aws-s3-no-public-buckets tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning tfsec:ignore:aws-s3-specify-public-access-block
resource "aws_s3_bucket" "default" {
  count = module.this.enabled ? 1 : 0

  bucket = "${module.this.id}-logs"
}

module "tfstate_backend" {
  source = "../../"

  force_destroy = true

  bucket_enabled   = var.bucket_enabled
  dynamodb_enabled = var.dynamodb_enabled

  logging = [
    {
      target_bucket = one(aws_s3_bucket.default[*].id)
      target_prefix = "tfstate/"
    }
  ]

  bucket_ownership_enforced_enabled = true

  context = module.this.context
}
