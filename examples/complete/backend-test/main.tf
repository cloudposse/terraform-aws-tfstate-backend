// This file is a minimal partial configuration of a Terraform component.
// We fill in the backend configuration with Terratest.
// All we really want to do is verify that some data is stored in the backend correctly,
// so we just store and test outputs without creating any resources.

terraform {
  backend "s3" {}
  required_version = ">= 1.0"
}

variable "test" {
  type        = string
  description = "Some input to save as output, for testing"
}

output "test" {
  value       = var.test
  description = "Some output that should be saved in the backend"
}
