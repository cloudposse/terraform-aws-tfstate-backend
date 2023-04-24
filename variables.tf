variable "arn_format" {
  type        = string
  description = "ARN format to be used. May be changed to support deployment in GovCloud/China regions."
  default     = "arn:aws"
}

variable "acl" {
  type        = string
  description = "The canned ACL to apply to the S3 bucket"
  default     = "private"
}

variable "billing_mode" {
  type        = string
  description = "DynamoDB billing mode"
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  type        = number
  description = "DynamoDB read capacity units when using provisioned mode"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "DynamoDB write capacity units when using provisioned mode"
  default     = 5
}

variable "force_destroy" {
  type        = bool
  description = "A boolean that indicates the S3 bucket can be destroyed even if it contains objects. These objects are not recoverable"
  default     = false
}

variable "mfa_delete" {
  type        = bool
  description = "A boolean that indicates that versions of S3 objects can only be deleted with MFA. ( Terraform cannot apply changes of this value; https://github.com/terraform-providers/terraform-provider-aws/issues/629 )"
  default     = false
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Enable DynamoDB point-in-time recovery"
  default     = true
}

variable "enable_public_access_block" {
  type        = bool
  description = "Enable Bucket Public Access Block"
  default     = true
}

variable "bucket_ownership_enforced_enabled" {
  type        = bool
  description = "Set bucket object ownership to \"BucketOwnerEnforced\". Disables ACLs."
  default     = true
}

variable "block_public_acls" {
  type        = bool
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  default     = true
}

variable "prevent_unencrypted_uploads" {
  type        = bool
  default     = true
  description = "Prevent uploads of unencrypted objects to S3"
}

variable "profile" {
  type        = string
  default     = ""
  description = "AWS profile name as set in the shared credentials file"
}

variable "role_arn" {
  type        = string
  default     = ""
  description = "The role to be assumed"
}

variable "terraform_backend_config_file_name" {
  type        = string
  default     = "terraform.tf"
  description = "(Deprecated) Name of terraform backend config file to generate"
}

variable "terraform_backend_config_file_path" {
  type        = string
  default     = ""
  description = "(Deprecated) Directory for the terraform backend config file, usually `.`. The default is to create no file."
}

variable "terraform_backend_config_template_file" {
  type        = string
  default     = ""
  description = "(Deprecated) The path to the template used to generate the config file"
}

variable "terraform_version" {
  type        = string
  default     = "1.0.0"
  description = "The minimum required terraform version"
}

variable "terraform_state_file" {
  type        = string
  default     = "terraform.tfstate"
  description = "The path to the state file inside the bucket"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name. If not provided, the name will be generated from the context by the label module."
  default     = ""

  validation {
    condition     = length(var.s3_bucket_name) < 64
    error_message = "A provided S3 bucket name must be fewer than 64 characters."
  }
}

variable "s3_replication_enabled" {
  type        = bool
  default     = false
  description = "Set this to true and specify `s3_replica_bucket_arn` to enable replication"
}

variable "s3_replica_bucket_arn" {
  type        = string
  default     = ""
  description = "The ARN of the S3 replica bucket (destination)"
}

variable "logging" {
  type = list(object({
    target_bucket = string
    target_prefix = string
  }))
  description = "Destination (S3 bucket name and prefix) for S3 Server Access Logs for the S3 bucket."
  default     = []
  validation {
    condition     = length(var.logging) < 2
    error_message = "Only 1 bucket logging configuration can be provided."
  }
}

variable "bucket_enabled" {
  type        = bool
  default     = true
  description = "Whether to create the S3 bucket."
}

variable "dynamodb_enabled" {
  type        = bool
  default     = true
  description = "Whether to create the DynamoDB table."
}

variable "dynamodb_table_name" {
  type        = string
  default     = null
  description = "Override the name of the DynamoDB table which defaults to using `module.dynamodb_table_label.id`"
}

variable "permissions_boundary" {
  type        = string
  default     = ""
  description = "ARN of the policy that is used to set the permissions boundary for the IAM replication role"
}
