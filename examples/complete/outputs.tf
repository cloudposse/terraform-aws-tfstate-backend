output "s3_bucket_ids" {
  description = "Names of the created S3 buckets"
  value       = module.tfstate.s3_bucket_ids
}

output "s3_bucket_arns" {
  description = "ARNs of the created S3 buckets"
  value       = module.tfstate.s3_bucket_arns
}

output "s3_bucket_domains" {
  description = "Map (by region) of the domain names of the created S3 buckets"
  value       = module.tfstate.s3_bucket_domains
}

output "s3_bucket_kms_key_arns" {
  description = "Map (by S3 bucket name) of the KMS key ARNs used to encrypt the S3 buckets"
  value       = module.tfstate.s3_bucket_kms_key_arns
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.tfstate.dynamodb_table_name
}

output "dynamodb_table_arns" {
  description = "DynamoDB table ARNs"
  value       = module.tfstate.dynamodb_table_arns
}

output "sns_topic_arns" {
  description = <<-EOT
    Map (by region) of the ARNs for the SNS Topics created by this module to receive
    replication event notifications regarding the created S3 bucket
    EOT
  value       = module.tfstate.sns_topic_arns
}

output "blue_backend_config" {
  value       = module.tfstate.blue_backend_config
  description = "Backend configuration for the blue Terraform state"
}

output "green_backend_config" {
  value       = module.tfstate.green_backend_config
  description = "Backend configuration for the green Terraform state"
}
