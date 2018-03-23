module "s3_bucket_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("terraform", "state")))}"]
  tags       = "${var.tags}"
}

resource "aws_s3_bucket" "default" {
  bucket        = "${module.s3_bucket_label.id}"
  acl           = "${var.acl}"
  region        = "${var.region}"
  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = "${module.s3_bucket_label.tags}"
}

module "dynamodb_table_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("terraform", "state", "lock")))}"]
  tags       = "${var.tags}"
}

resource "aws_dynamodb_table" "default" {
  name           = "${module.dynamodb_table_label.id}"
  read_capacity  = "${var.autoscale_min_read_capacity}"
  write_capacity = "${var.autoscale_min_write_capacity}"
  hash_key       = "LockID"                              # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    ignore_changes = ["read_capacity", "write_capacity"]
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = "${module.dynamodb_table_label.tags}"
}

module "dynamodb_autoscaler" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-dynamodb-autoscaler.git?ref=tags/0.1.0"
  namespace                    = "${var.namespace}"
  stage                        = "${var.stage}"
  name                         = "${var.name}"
  delimiter                    = "${var.delimiter}"
  attributes                   = "${var.attributes}"
  dynamodb_table_name          = "${aws_dynamodb_table.default.id}"
  dynamodb_table_arn           = "${aws_dynamodb_table.default.arn}"
  autoscale_write_target       = "${var.autoscale_write_target}"
  autoscale_read_target        = "${var.autoscale_read_target}"
  autoscale_min_read_capacity  = "${var.autoscale_min_read_capacity}"
  autoscale_max_read_capacity  = "${var.autoscale_max_read_capacity}"
  autoscale_min_write_capacity = "${var.autoscale_min_write_capacity}"
  autoscale_max_write_capacity = "${var.autoscale_max_write_capacity}"
}
