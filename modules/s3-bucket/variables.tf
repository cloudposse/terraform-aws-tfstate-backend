variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "kms_key_arn" {
  type        = list(string)
  description = "the ARN of the KMS key to use for server-side encryption"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "bucket_logging" {
  type = list(object({
    target_bucket = string
    target_prefix = string
  }))
  description = "Destination for S3 Server Access Logs for the bucket."
  default     = []
}

variable "sns_enabled" {
  type        = bool
  description = "Whether to enable SNS notifications for replication failures"
  default     = false
}

variable "force_destroy" {
  type        = bool
  description = <<-EOT
    FOR TESTING ONLY! When set to true, `terraform destroy` will destroy the S3 buckets and all the objects in them.
    These objects are not recoverable even if you have versioning or backups enabled.
    EOT
  default     = false
}
