output "s3_bucket_domain_name" {
  value = "${module.s3_bucket.bucket_domain_name}"
}

output "s3_bucket_id" {
  value = "${module.s3_bucket.id}"
}

output "s3_bucket_arn" {
  value = "${module.s3_bucket.arn}"
}

output "dynamodb_table_id" {
  value = "${module.dynamodb_table.table_id}"
}

output "dynamodb_table_arn" {
  value = "${module.dynamodb_table.table_arn}"
}

output "dynamodb_table_name" {
  value = "${module.dynamodb_table.table_name}"
}
