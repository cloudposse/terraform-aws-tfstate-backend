module "tfstate_backend" {
  source = "../../"

  providers = {
    aws      = "aws"
    null     = "null"
    local    = "local"
    template = "template"
  }

  region    = var.region
  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  force_destroy = true
}
