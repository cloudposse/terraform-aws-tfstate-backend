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
  value = "${aws_dynamodb_table.default.name}"
}

output "dynamodb_table_id" {
  value = "${aws_dynamodb_table.default.id}"
}

output "dynamodb_table_arn" {
  value = "${aws_dynamodb_table.default.arn}"
}
