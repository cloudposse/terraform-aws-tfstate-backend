variable "blue_s3_bucket_name" {
  type        = list(string)
  description = "S3 bucket name for bucket in blue region. If not provided, the name will be generated from context."
  default     = []
  validation {
    condition     = length(var.blue_s3_bucket_name) < 2 && try(length(var.blue_s3_bucket_name[0]), 0) <= 63
    error_message = "Only 1 blue_s3_bucket_name can be provided, and it must be no more than 63 characters."
  }
}

variable "blue_kms_key_arn" {
  type        = list(string)
  description = <<-EOT
    The KMS Key ARN for encrypting object (SSE-KMS) in the blue bucket. Default is to use default (SSE-S3) key.
    Note: If you are not using the default key and have replication enabled, you must grant the replication role
    permission to use the key (`kms:Encrypt` and `kms:Decrypt`).
    EOT
  default     = []
  validation {
    condition     = length(var.blue_kms_key_arn) < 2
    error_message = "Only 1 blue_kms_key_arn can be provided."
  }
}

variable "green_s3_bucket_name" {
  type        = list(string)
  description = "S3 bucket name for bucket in green region. If not provided, the name will be generated from context."
  default     = []
  validation {
    condition     = length(var.green_s3_bucket_name) < 2 && try(length(var.green_s3_bucket_name[0]), 0) <= 63
    error_message = "Only 1 green_s3_bucket_name can be provided, and it must be no more than 63 characters."
  }
}

variable "green_kms_key_arn" {
  type        = list(string)
  description = "The KMS Key ARN for encrypting object (SSE-KMS) in the green bucket. Default is to use default (SSE-S3) key."
  default     = []
  validation {
    condition     = length(var.green_kms_key_arn) < 2
    error_message = "Only 1 green_kms_key_arn can be provided."
  }
}

variable "replication_enabled" {
  type        = bool
  description = <<-EOT
    Set true to enable bidirectional replication and creation of hot standby for quick failover. Highly recommended.
    If set to `false`, the "green" configuration will be ignored.
    Replication is not supported in AWS GovCloud (US) because S3 Replication Time Control (S3 RTC) is not available.
    EOT
  default     = true
}

variable "replication_role_name" {
  type        = list(string)
  description = "The name to give to the IAM role created for replication. If not provided, the name will be generated from context."
  default     = []
  validation {
    condition     = length(var.replication_role_name) < 2 && try(length(var.replication_role_name[0]), 0) <= 64
    error_message = "Only 1 replication_role_name can be provided, and it must be no more than 64 characters."
  }
}

variable "lock_table_enabled" {
  type        = bool
  description = <<-EOT
    Set true to create a DynamoDB table to provide Terraform state locking. Highly recommended.
    If replication is enabled, a global DynamoDB table will be created in both the blue and green regions.
    EOT
  default     = true
}

variable "dynamodb_table_name" {
  type        = list(string)
  description = "The name of the DynamoDB table. If not provided, the name will be generated from context."
  default     = []
  validation {
    condition     = length(var.dynamodb_table_name) < 2
    error_message = "Only 1 dynamodb_table_name can be provided."
  }
}

variable "permissions_boundary" {
  type        = list(string)
  description = "The ARN of the policy that sets the permissions boundary for the IAM role used for replication."
  default     = []
  validation {
    condition     = length(var.permissions_boundary) < 2
    error_message = "Only 1 permissions_boundary can be provided."
  }
}

variable "blue_bucket_logging" {
  type = list(object({
    target_bucket = string
    target_prefix = string
  }))
  description = "Destination for S3 Server Access Logs for the blue bucket."
  default     = []
  validation {
    condition     = length(var.blue_bucket_logging) < 2
    error_message = "Only 1 blue bucket logging configuration can be provided."
  }
}

variable "green_bucket_logging" {
  type = list(object({
    target_bucket = string
    target_prefix = string
  }))
  description = "Destination for S3 Server Access Logs for the green bucket."
  default     = []
  validation {
    condition     = length(var.green_bucket_logging) < 2
    error_message = "Only 1 green bucket logging configuration can be provided."
  }
}

variable "force_destroy" {
  type        = bool
  description = <<-EOT
    FOR TESTING ONLY! When set to true, `terraform destroy` will destroy the S3 buckets and all the objects in them.
    These objects are not recoverable even if you have versioning or backups enabled.
    EOT
  default     = false
}
