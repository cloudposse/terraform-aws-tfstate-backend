module "tfstate_backend" {
  source = "../../"

  providers = {
    aws = "aws"
  }

  region    = var.region
  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  force_destroy = true
}
