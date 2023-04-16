output "s3_bucket_ids" {
  description = "Map (by region) of the IDs (names) of the created S3 buckets"
  value       = local.enabled ? { for k in local.colors : local.s3_regions[k] => local.s3_bucket_names[k] } : null
}

output "s3_bucket_arns" {
  description = "Map (by region) of the ARNs of the created S3 buckets"
  value = local.enabled ? {
    for k in local.colors : local.s3_buckets[k].region => local.s3_buckets[k].arn
  } : null
}

output "s3_bucket_domains" {
  description = "Map (by region) of the domain names of the created S3 buckets"
  value = local.enabled ? {
    for k in local.colors : local.s3_buckets[k].region => local.s3_buckets[k].bucket_regional_domain_name
  } : null
}

output "s3_bucket_kms_key_arns" {
  description = "Map (by bucket name) of the ARNs of the KMS keys used to encrypt the created S3 buckets"
  value = local.enabled ? merge({
    (module.blue_bucket[0].bucket.id) = local.blue_kms_key_arn },
    local.replication_enabled ? {
    (module.green_bucket[0].bucket.id) = local.green_kms_key_arn } : {}
  ) : null
}

output "sns_topic_arns" {
  description = <<-EOT
    Map (by region) of the ARNs for the SNS Topics created by this module to receive
    replication event notifications regarding the created S3 bucket
    EOT
  value = local.replication_enabled ? try({
    (module.blue_bucket[0].bucket.region)  = (module.blue_bucket[0].sns_topic)
    (module.green_bucket[0].bucket.region) = (module.green_bucket[0].sns_topic)
  }, null) : null
}

output "dynamodb_table_id" {
  value       = one(aws_dynamodb_table.locks[*].id)
  description = "DynamoDB table ID"
}

output "dynamodb_table_name" {
  value       = one(aws_dynamodb_table.locks[*].name)
  description = "DynamoDB table name"
}

output "dynamodb_table_arns" {
  value = local.lock_table_enabled ? merge({
    (local.blue_region) = one(aws_dynamodb_table.locks[*].arn) },
    local.replication_enabled ? {
    (local.green_region) = one(aws_dynamodb_table.locks[*]) == null ? null : one(aws_dynamodb_table.locks[0].replica[*].arn) } : {}
  ) : null
  description = <<-EOT
    Map (by region) of the ARNs for DynamoDB tables created by this module to store Terraform state locks.
    Note that in general you should only refer to the tables by name and region, not by ARN.
    EOT
}

output "blue_backend_config" {
  value       = local.blue_backend_config
  description = "Backend configuration for the blue Terraform state"
}

output "green_backend_config" {
  value       = local.green_backend_config
  description = "Backend configuration for the green Terraform state"
}

#### Deprecated Outputs
# These outputs are holdovers from version 0 of this module and are only
# supported when the `replication_enabled` variable is set to `false`.

output "s3_bucket_arn" {
  value       = local.replication_enabled ? null : try(local.s3_buckets["blue"].arn, null)
  description = "(Deprecated, use `s3_bucket_arns` instead): S3 bucket ARN"
}

output "s3_bucket_domain_name" {
  value       = local.replication_enabled ? null : try(local.s3_buckets["blue"].bucket_domain_name, null)
  description = "(Deprecated, use `s3_bucket_domains` instead): S3 bucket domain name"
}

output "s3_bucket_id" {
  value       = local.replication_enabled ? null : try(local.s3_buckets["blue"].id, null)
  description = "(Deprecated, use `s3_bucket_ids` instead): S3 bucket ID"
}


output "dynamodb_table_arn" {
  value       = local.replication_enabled ? null : one(aws_dynamodb_table.locks[*].arn)
  description = "(Deprecated, use `dynamodb_table_arns` instead) DynamoDB table ARN"
}
