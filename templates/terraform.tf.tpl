terraform {
  required_version = ">= 0.11.3"

  backend "s3" {
    region         = "${region}"
    bucket         = "${bucket}"
    key            = "terraform.tfstate"
    dynamodb_table = "${dynamodb_table}"
    encrypt        = "${encrypt}"
  }
}
