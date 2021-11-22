provider "aws" {
  region = var.region
}

module "tfstate_backend" {
  source = "../../"

  force_destroy = true

  bucket_enabled   = var.bucket_enabled
  dynamodb_enabled = false
  enable_server_side_encryption = false

  context = module.this.context
}
