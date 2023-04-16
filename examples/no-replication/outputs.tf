output "s3_bucket_id" {
  value       = module.tfstate_backend.s3_bucket_id
  description = "S3 bucket ID"
}

output "dynamodb_table_name" {
  value       = module.tfstate_backend.dynamodb_table_name
  description = "DynamoDB table name"
}

output "dynamodb_table_id" {
  value       = module.tfstate_backend.dynamodb_table_id
  description = "DynamoDB table ID"
}

output "backend_config" {
  value       = module.tfstate_backend.blue_backend_config
  description = "Terraform state backend configuration (as a map)"
}
