provider "aws" {
  region = var.region
}

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
