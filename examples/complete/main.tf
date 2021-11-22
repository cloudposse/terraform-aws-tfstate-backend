provider "aws" {
  region = var.region
}

module "tfstate_backend" {
  source = "../../"

  force_destroy = true

  bucket_enabled   = var.bucket_enabled
  dynamodb_enabled = var.dynamodb_enabled

  s3_replication_enabled = true
  s3_replica_bucket_arn  = module.tstate_backend_replication.s3_bucket_arn

  context = module.this.context
}

module "tstate_backend_replication" {
  source = "../../"

  s3_bucket_name   = "${module.this.id}-replica"
  force_destroy    = true
  dynamodb_enabled = false

}
