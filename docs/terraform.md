
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl | The canned ACL to apply to the S3 bucket | string | `private` | no |
| attributes | Additional attributes (e.g. `state`) | list | `<list>` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes` | string | `-` | no |
| enable_server_side_encryption | Enable DynamoDB server-side encryption | string | `true` | no |
| force_destroy | A boolean that indicates the S3 bucket can be destroyed even if it contains objects. These objects are not recoverable | string | `false` | no |
| mfa_delete | A boolean that indicates that versions of S3 objects can only be deleted with MFA. ( Terraform cannot apply changes of this value; https://github.com/terraform-providers/terraform-provider-aws/issues/629 ) | string | `false` | no |
| name | Name  (e.g. `app` or `cluster`) | string | `terraform` | no |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | string | - | yes |
| read_capacity | DynamoDB read capacity units | string | `5` | no |
| region | AWS Region the S3 bucket should reside in | string | - | yes |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map | `<map>` | no |
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

