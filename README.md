# terraform-aws-state-backend [![Build Status](https://travis-ci.org/cloudposse/terraform-aws-state-backend.svg?branch=master)](https://travis-ci.org/cloudposse/terraform-aws-state-backend)

Provision an S3 bucket to store `terraform.tfstate` file and a DynamoDB table to lock the state file to prevent concurrent modifications and state corruption.

__NOTE:__ The operators of the module (IAM Users) must have permissions to create S3 buckets and DynamoDB tables when performing `terraform plan` and `terraform apply`


## Usage

```hcl
module "terraform_state_backend" {
  source        = "git::https://github.com/cloudposse/terraform-aws-state-backend.git?ref=master"
  namespace     = "cp"
  stage         = "dev"
  name          = "cluster"
  region        = "us-east-1"
  hash_key      = "LockID"
}
```

Once the S3 bucket and DynamoDB table have been created, configure Terraform backend to use them

```hcl
terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "${module.terraform_state_backend.s3_bucket_id}"
    key            = "terraform.tfstate"
    dynamodb_table = "${module.terraform_state_backend.dynamodb_table_name}"
  }
}
```


## Variables

|  Name                           |  Default     |  Description                                                                           | Required |
|:--------------------------------|:-------------|:---------------------------------------------------------------------------------------|:--------:|
| `namespace`                     | ``           | Namespace (_e.g._ `cp` or `cloudposse`)                                                | Yes      |
| `stage`                         | ``           | Stage (_e.g._ `prod`, `dev`, `staging`)                                                | Yes      |
| `name`                          | ``           | Name  (_e.g._ `app` or `cluster`)                                                      | Yes      |
| `region`                        | ``           | AWS Region the S3 bucket should reside in                                              | Yes      |
| `attributes`                    | `[]`         | Additional attributes (_e.g._ `policy` or `role`)                                      | No       |
| `tags`                          | `{}`         | Additional tags  (_e.g._ `map("BusinessUnit","XYZ")`                                   | No       |
| `delimiter`                     | `-`          | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`            | No       |
| `acl`                           | `private`    | The canned ACL to apply to the S3 bucket                                               | No       |
| `force_destroy`                 | `false`      | Indicates that all objects should be deleted from the S3 bucket so that it can be destroyed without errors   | No       |
| `lifecycle_rule_enabled`        | `false`      | Enable lifecycle events on the bucket                                                  | No       |
| `versioning_enabled`            | `true`       | Enable versioning to keep multiple variants of an object in the same bucket            | No       |
| `encrypt_dynamodb`              | `true`       | Enable encryption of DynamoDB                                                          | No       |
| `hash_key`                      | `LockID`     | The attribute in the DynamoDB table to use as the hash key                             | No       |
| `autoscale_write_target`        | `5`          | The target value for DynamoDB write autoscaling                                        | No       |
| `autoscale_read_target`         | `5`          | The target value for DynamoDB read autoscaling                                         | No       |
| `autoscale_min_read_capacity`   | `5`          | DynamoDB autoscaling min read capacity                                                 | No       |
| `autoscale_max_read_capacity`   | `50`         | DynamoDB autoscaling max read capacity                                                 | No       |
| `autoscale_min_write_capacity`  | `5`          | DynamoDB autoscaling min write capacity                                                | No       |
| `autoscale_max_write_capacity`  | `50`         | DynamoDB autoscaling max write capacity                                                | No       |


## Outputs

| Name                     | Description                            |
|:-------------------------|:---------------------------------------|
| `s3_bucket_domain_name`  | S3 bucket domain name                  |
| `s3_bucket_id`           | S3 bucket ID                           |
| `s3_bucket_arn`          | S3 bucket ARN                          |
| `dynamodb_table_id`      | DynamoDB table ID                      |
| `dynamodb_table_arn`     | DynamoDB table ARN                     |
| `dynamodb_table_name`    | DynamoDB table name                    |


## Help

**Got a question?**

File a GitHub [issue](https://github.com/cloudposse/terraform-aws-state-backend/issues), send us an [email](mailto:hello@cloudposse.com) or reach out to us on [Gitter](https://gitter.im/cloudposse/).


## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/terraform-aws-state-backend/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing `terraform-aws-state-backend`, we would love to hear from you! Shoot us an [email](mailto:hello@cloudposse.com).

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull request** so that we can review your changes

**NOTE:** Be sure to merge the latest from "upstream" before making a pull request!


## License

[APACHE 2.0](LICENSE) © 2018 [Cloud Posse, LLC](https://cloudposse.com)

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.


## About

`terraform-aws-state-backend` is maintained and funded by [Cloud Posse, LLC][website].

![Cloud Posse](https://cloudposse.com/logo-300x69.png)


Like it? Please let us know at <hello@cloudposse.com>

We love [Open Source Software](https://github.com/cloudposse/)!

See [our other projects][community]
or [hire us][hire] to help build your next cloud platform.

  [website]: https://cloudposse.com/
  [community]: https://github.com/cloudposse/
  [hire]: https://cloudposse.com/contact/


### Contributors

| [![Erik Osterman][erik_img]][erik_web]<br/>[Erik Osterman][erik_web] | [![Andriy Knysh][andriy_img]][andriy_web]<br/>[Andriy Knysh][andriy_web] |
|-------------------------------------------------------|------------------------------------------------------------------|

  [erik_img]: http://s.gravatar.com/avatar/88c480d4f73b813904e00a5695a454cb?s=144
  [erik_web]: https://github.com/osterman/
  [andriy_img]: https://avatars0.githubusercontent.com/u/7356997?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
  [andriy_web]: https://github.com/aknysh/
