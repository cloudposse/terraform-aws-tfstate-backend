terraform {
  required_version = "~> 0.12.0"
}

# Pin the `aws` provider
# https://www.terraform.io/docs/configuration/providers.html
# Any non-beta version >= 2.0.0 and < 3.0.0, e.g. 2.X.Y
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}
