provider "aws" {
  region = var.region
}

module "tfstate_backend" {
  source = "../../"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  force_destroy = true
}
