provider "aws" {
  region = var.region
}

module "tfstate_backend" {
  source = "../../"

  force_destroy = true

  context = module.this.context
}
