variable "region" {
  type        = string
  description = "AWS region"
}

variable "bucket_enabled" {
  type        = bool
  default     = true
  description = "Whether to create the s3 bucket."
}

variable "dynamodb_enabled" {
  type        = bool
  default     = true
  description = "Whether to create the dynamodb table."
}
