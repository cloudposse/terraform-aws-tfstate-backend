provider "aws" {
  region = var.region
}

module "tfstate_backend" {
  source = "../../"

  providers = {
    aws.blue  = aws
    aws.green = aws
  }

  force_destroy = true

  replication_enabled = false

  context = module.this.context
}
