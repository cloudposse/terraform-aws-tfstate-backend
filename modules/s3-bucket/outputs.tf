output "bucket" {
  value       = aws_s3_bucket.each
  description = "The metadata for the S3 bucket created by this module"
}

output "sns_topic" {
  value       = aws_sns_topic.replication
  description = <<-EOT
    The metadata for the SNS Topic created by this module to receive
    replication event notifications regarding the created S3 bucket
    EOT
}
