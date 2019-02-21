module "base_label" {
  source             = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.5.3"
  namespace          = "${var.namespace}"
  environment        = "${var.environment}"
  stage              = "${var.stage}"
  name               = "${var.name}"
  delimiter          = "${var.delimiter}"
  attributes         = "${var.attributes}"
  tags               = "${var.tags}"
  additional_tag_map = "${var.additional_tag_map}"
  context            = "${var.context}"
  label_order        = "${var.label_order}"
}

module "s3_bucket_label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.5.3"
  context = "${module.base_label.context}"
}

resource "aws_s3_bucket" "default" {
  bucket        = "${module.s3_bucket_label.id}"
  acl           = "${var.acl}"
  region        = "${var.region}"
  force_destroy = "${var.force_destroy}"

  versioning {
    enabled    = true
    mfa_delete = "${var.mfa_delete}"
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

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = "${aws_s3_bucket.default.id}"
  block_public_acls       = "${var.block_public_acls}"
  ignore_public_acls      = "${var.ignore_public_acls}"
  block_public_policy     = "${var.block_public_policy}"
  restrict_public_buckets = "${var.restrict_public_buckets}"
}

module "dynamodb_table_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.5.3"
  context    = "${module.base_label.context}"
  attributes = ["${compact(concat(var.attributes, list("lock")))}"]
}

resource "aws_dynamodb_table" "with_server_side_encryption" {
  count          = "${var.enable_server_side_encryption == "true" ? 1 : 0}"
  name           = "${module.dynamodb_table_label.id}"
  read_capacity  = "${var.read_capacity}"
  write_capacity = "${var.write_capacity}"
  hash_key       = "LockID"                                                 # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table

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

resource "aws_dynamodb_table" "without_server_side_encryption" {
  count          = "${var.enable_server_side_encryption == "true" ? 0 : 1}"
  name           = "${module.dynamodb_table_label.id}"
  read_capacity  = "${var.read_capacity}"
  write_capacity = "${var.write_capacity}"
  hash_key       = "LockID"

  lifecycle {
    ignore_changes = ["read_capacity", "write_capacity"]
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = "${module.dynamodb_table_label.tags}"
}
