locals {
  az_map            = module.region_utils.region_az_alt_code_maps["to_short"]
  blue_environment  = try(local.az_map[local.blue_region], "blue")
  green_environment = try(local.az_map[local.green_region], "green")
}

module "region_utils" {
  source  = "cloudposse/utils/aws"
  version = "1.1.0"

  context = module.this.context
}

module "blue_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  environment = local.replication_enabled ? local.blue_environment : module.this.environment

  id_length_limit = 63

  context = module.this.context
}

module "green_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  environment = local.green_environment

  id_length_limit = 63

  context = module.this.context
}

module "replication_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled     = local.replication_enabled
  environment = "gbl"
  attributes  = ["replication"]

  id_length_limit = 64

  context = module.this.context
}

module "dynamodb_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  environment = var.replication_enabled ? "gbl" : module.blue_label.environment
  attributes  = ["lock"]

  context = module.this.context
}
