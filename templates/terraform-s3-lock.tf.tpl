terraform {
  required_version = ">= ${terraform_version}"

  backend "s3" {
    region  = "${region}"
    bucket  = "${bucket}"
    key     = "${terraform_state_file}"
    profile = "${profile}"
    encrypt = "${encrypt}"
    %{~ if role_arn != "" ~}

    assume_role {
      role_arn = "${role_arn}"
    }
    %{~ endif ~}
    %{~ if ! use_lockfile ~}

    dynamodb_table = "${dynamodb_table}"
    %{~ else ~}

    use_lockfile     = "${use_lockfile}"
    %{~ endif ~}
  }
}
