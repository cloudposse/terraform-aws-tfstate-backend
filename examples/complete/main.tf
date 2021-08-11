provider "aws" {
  region = var.region
}

module "tfstate_backend" {
  source = "../../"

  force_destroy = true

  bucket_enabled   = var.bucket_enabled
  dynamodb_enabled = var.dynamodb_enabled

  context = module.this.context
}
