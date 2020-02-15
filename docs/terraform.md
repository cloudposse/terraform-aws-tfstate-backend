## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl | The canned ACL to apply to the S3 bucket | string | `private` | no |
| additional_tag_map | Additional tags for appending to each tag map | map(string) | `<map>` | no |
| attributes | Additional attributes (e.g. `state`) | list(string) | `<list>` | no |
| block_public_acls | Whether Amazon S3 should block public ACLs for this bucket | bool | `true` | no |
| block_public_policy | Whether Amazon S3 should block public bucket policies for this bucket | string | `true` | no |
| context | Default context to use for passing state between label invocations | object | `<map>` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | string | `-` | no |
| enable_point_in_time_recovery | Enable DynamoDB point in time recovery | bool | `false` | no |
| enable_server_side_encryption | Enable DynamoDB server-side encryption | bool | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | string | `` | no |
| force_destroy | A boolean that indicates the S3 bucket can be destroyed even if it contains objects. These objects are not recoverable | bool | `false` | no |
| ignore_public_acls | Whether Amazon S3 should ignore public ACLs for this bucket | bool | `true` | no |
| label_order | The naming order of the id output and Name tag | list(string) | `<list>` | no |
| mfa_delete | A boolean that indicates that versions of S3 objects can only be deleted with MFA. ( Terraform cannot apply changes of this value; https://github.com/terraform-providers/terraform-provider-aws/issues/629 ) | bool | `false` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `terraform` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| prevent_unencrypted_uploads | Prevent uploads of unencrypted objects to S3 | bool | `true` | no |
| profile | AWS profile name as set in the shared credentials file | string | `` | no |
| read_capacity | DynamoDB read capacity units | string | `5` | no |
| regex_replace_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | string | `/[^a-zA-Z0-9-]/` | no |
| region | AWS Region the S3 bucket should reside in | string | - | yes |
| restrict_public_buckets | Whether Amazon S3 should restrict public bucket policies for this bucket | bool | `true` | no |
| role_arn | The role to be assumed | string | `` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | string | `` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | map(string) | `<map>` | no |
| terraform_backend_config_file_name | Name of terraform backend config file | string | `terraform.tf` | no |
| terraform_backend_config_file_path | The path to terrafrom project directory | string | `` | no |
| terraform_state_file | The path to the state file inside the bucket | string | `terraform.tfstate` | no |
| terraform_version | The minimum required terraform version | string | `0.12.2` | no |
| write_capacity | DynamoDB write capacity units | string | `5` | no |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb_table_arn | DynamoDB table ARN |
| dynamodb_table_id | DynamoDB table ID |
| dynamodb_table_name | DynamoDB table name |
| s3_bucket_arn | S3 bucket ARN |
| s3_bucket_domain_name | S3 bucket domain name |
| s3_bucket_id | S3 bucket ID |
| terraform_backend_config | Rendered Terraform backend config file |

