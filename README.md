# terraform-aws-state-backend

Provision a remote AWS S3 bucket to store `terraform.tfstate` file and a DynamoDB table to lock the state file and prevent concurrent edits


## Usage

```hcl
module "terraform_aws_state_backend" {
  source            = "git::https://github.com/cloudposse/terraform-aws-state-backend.git?ref=master"
  namespace         = "cp"
  stage             = "dev"
  name              = "cluster"
}
```


## Variables

|  Name                 |  Default                          |  Description                                                                             | Required |
|:----------------------|:----------------------------------|:-----------------------------------------------------------------------------------------|:--------:|
| `namespace`           | ``                                | Namespace (_e.g._ `cp` or `cloudposse`)                                                  | Yes      |
| `stage`               | ``                                | Stage (_e.g._ `prod`, `dev`, `staging`)                                                  | Yes      |
| `name`                | ``                                | Name  (_e.g._ `app` or `cluster`)                                                        | Yes      |
| `attributes`          | `[]`                              | Additional attributes (_e.g._ `policy` or `role`)                                        | No       |
| `tags`                | `{}`                              | Additional tags  (_e.g._ `map("BusinessUnit","XYZ")`                                     | No       |
| `delimiter`           | `-`                               | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`              | No       |


## Outputs

| Name                | Description                            |
|:--------------------|:---------------------------------------|
| ``                  |                                        |
