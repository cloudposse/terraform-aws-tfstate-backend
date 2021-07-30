output "s3_bucket_domain_name" {
  value       = join("", aws_s3_bucket.default.*.bucket_domain_name)
  description = "S3 bucket domain name"
}

output "s3_bucket_id" {
  value       = join("", aws_s3_bucket.default.*.id)
  description = "S3 bucket ID"
}

output "s3_bucket_arn" {
  value       = join("", aws_s3_bucket.default.*.arn)
  description = "S3 bucket ARN"
}

output "dynamodb_table_name" {
  value = element(
    coalescelist(
      aws_dynamodb_table.with_server_side_encryption.*.name,
      aws_dynamodb_table.without_server_side_encryption.*.name,
      [""]
    ),
    0
  )
  description = "DynamoDB table name"
}

output "dynamodb_table_id" {
  value = element(
    coalescelist(
      aws_dynamodb_table.with_server_side_encryption.*.id,
      aws_dynamodb_table.without_server_side_encryption.*.id,
      [""]
    ),
    0
  )
  description = "DynamoDB table ID"
}

output "dynamodb_table_arn" {
  value = element(
    coalescelist(
      aws_dynamodb_table.with_server_side_encryption.*.arn,
      aws_dynamodb_table.without_server_side_encryption.*.arn,
      [""]
    ),
    0
  )
  description = "DynamoDB table ARN"
}

output "terraform_backend_config" {
  value       = join("", data.template_file.terraform_backend_config.*.rendered)
  description = "Rendered Terraform backend config file"
}
