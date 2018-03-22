variable "namespace" {
  type        = "string"
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`, `infra`)"
}

variable "name" {
  type        = "string"
  description = "Name  (e.g. `app` or `cluster`)"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map('BusinessUnit`,`XYZ`)"
}

variable "region" {
  type        = "string"
  description = "AWS Region the S3 bucket should reside in"
  default     = "us-east-1"
}

variable "acl" {
  type        = "string"
  description = "The canned ACL to apply to the S3 bucket"
  default     = "private"
}

variable "encrypt_dynamodb" {
  description = "Enable encryption of DynamoDB"
  default     = "true"
}

variable "hash_key" {
  type        = "string"
  default     = "LockID"
  description = "The attribute in the DynamoDB table to use as the hash key"
}

variable "autoscale_write_target" {
  default     = 20
  description = "The target value for DynamoDB write autoscaling"
}

variable "autoscale_read_target" {
  default     = 20
  description = "The target value for DynamoDB read autoscaling"
}

variable "autoscale_min_read_capacity" {
  default     = 10
  description = "DynamoDB autoscaling min read capacity"
}

variable "autoscale_max_read_capacity" {
  default     = 100
  description = "DynamoDB autoscaling max read capacity"
}

variable "autoscale_min_write_capacity" {
  default     = 10
  description = "DynamoDB autoscaling min write capacity"
}

variable "autoscale_max_write_capacity" {
  default     = 100
  description = "DynamoDB autoscaling max write capacity"
}
