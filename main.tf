module "s3_bucket" {
  source                 = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.2.0"
  stage                  = "${var.stage}"
  namespace              = "${var.namespace}"
  name                   = "${var.name}"
  region                 = "${var.region}"
  acl                    = "${var.acl}"
  force_destroy          = "${var.force_destroy}"
  versioning_enabled     = "${var.versioning_enabled}"
  lifecycle_rule_enabled = "${var.lifecycle_rule_enabled}"
  delimiter              = "${var.delimiter}"
  attributes             = ["${compact(concat(var.attributes, list("terraform", "state")))}"]
  tags                   = "${var.tags}"
}

module "dynamodb_table" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-dynamodb.git?ref=tags/0.2.1"
  namespace                    = "${var.namespace}"
  stage                        = "${var.stage}"
  name                         = "${var.name}"
  delimiter                    = "${var.delimiter}"
  attributes                   = ["${compact(concat(var.attributes, list("terraform", "state", "lock")))}"]
  tags                         = "${var.tags}"
  enable_encryption            = "${var.encrypt_dynamodb}"
  hash_key                     = "${var.hash_key}"
  autoscale_read_target        = "${var.autoscale_read_target}"
  autoscale_write_target       = "${var.autoscale_write_target}"
  autoscale_min_read_capacity  = "${var.autoscale_min_read_capacity}"
  autoscale_max_read_capacity  = "${var.autoscale_max_read_capacity}"
  autoscale_min_write_capacity = "${var.autoscale_min_write_capacity}"
  autoscale_max_write_capacity = "${var.autoscale_max_write_capacity}"
}
