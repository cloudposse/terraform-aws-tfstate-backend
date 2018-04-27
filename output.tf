output "s3_bucket_domain_name" {
  value = "${aws_s3_bucket.default.bucket_domain_name}"
}

output "s3_bucket_id" {
  value = "${aws_s3_bucket.default.id}"
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.default.arn}"
}

output "dynamodb_table_name" {
  value = "${element(coalescelist(aws_dynamodb_table.with_server_side_encryption.*.name, aws_dynamodb_table.without_server_side_encryption.*.name), 0)}"
}

output "dynamodb_table_id" {
  value = "${element(coalescelist(aws_dynamodb_table.with_server_side_encryption.*.id, aws_dynamodb_table.without_server_side_encryption.*.id), 0)}"
}

output "dynamodb_table_arn" {
  value = "${element(coalescelist(aws_dynamodb_table.with_server_side_encryption.*.arn, aws_dynamodb_table.without_server_side_encryption.*.arn), 0)}"
}
