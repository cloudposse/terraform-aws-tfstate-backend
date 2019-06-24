module "tfstate_backend" {
  source = "../../"

  region    = var.region
  namespace = var.namespace
  stage     = var.stage
  name      = var.name

  force_destroy = true

  providers = {
    aws      = "aws"
    null     = "null"
    local    = "local"
    template = "template"
  }
}
