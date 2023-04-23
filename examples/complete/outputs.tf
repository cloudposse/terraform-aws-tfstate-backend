output "s3_bucket_id" {
  value       = module.tfstate_backend.s3_bucket_id
  description = "S3 bucket ID"
}

output "s3_replication_role_arn" {
  value       = module.tfstate_backend.s3_replication_role_arn
  description = "The ARN of the IAM Role created for replication, if enabled."
}

output "dynamodb_table_name" {
  value       = module.tfstate_backend.dynamodb_table_name
  description = "DynamoDB table name"
}

output "dynamodb_table_id" {
  value       = module.tfstate_backend.dynamodb_table_id
  description = "DynamoDB table ID"
}
