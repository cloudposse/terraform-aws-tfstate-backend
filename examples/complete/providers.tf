provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "green"
  region = coalesce(var.green_region, var.region)
}
