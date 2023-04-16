<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.63.0 |
| <a name="provider_aws.blue"></a> [aws.blue](#provider\_aws.blue) | 4.63.0 |
| <a name="provider_aws.green"></a> [aws.green](#provider\_aws.green) | 4.63.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_blue_bucket"></a> [blue\_bucket](#module\_blue\_bucket) | ./modules/s3-bucket | n/a |
| <a name="module_blue_label"></a> [blue\_label](#module\_blue\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_dynamodb_label"></a> [dynamodb\_label](#module\_dynamodb\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_green_bucket"></a> [green\_bucket](#module\_green\_bucket) | ./modules/s3-bucket | n/a |
| <a name="module_green_label"></a> [green\_label](#module\_green\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_region_utils"></a> [region\_utils](#module\_region\_utils) | cloudposse/utils/aws | 1.1.0 |
| <a name="module_replication_label"></a> [replication\_label](#module\_replication\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.locks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket_replication_configuration.blue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_replication_configuration.green](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_iam_policy_document.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.replication_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.blue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_kms_alias.green](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_region.blue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.green](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br>This is for some rare cases where resources want additional configuration of tags<br>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br>in the order they appear in the list. New attributes are appended to the<br>end of the list. The elements of the list are joined by the `delimiter`<br>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_blue_bucket_logging"></a> [blue\_bucket\_logging](#input\_blue\_bucket\_logging) | Destination for S3 Server Access Logs for the blue bucket. | <pre>list(object({<br>    target_bucket = string<br>    target_prefix = string<br>  }))</pre> | `[]` | no |
| <a name="input_blue_kms_key_arn"></a> [blue\_kms\_key\_arn](#input\_blue\_kms\_key\_arn) | The KMS Key ARN for encrypting object (SSE-KMS) in the blue bucket. Default is to use default (SSE-S3) key.<br>Note: If you are not using the default key and have replication enabled, you must grant the replication role<br>permission to use the key (`kms:Encrypt` and `kms:Decrypt`). | `list(string)` | `[]` | no |
| <a name="input_blue_s3_bucket_name"></a> [blue\_s3\_bucket\_name](#input\_blue\_s3\_bucket\_name) | S3 bucket name for bucket in blue region. If not provided, the name will be generated from context. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "descriptor_formats": {},<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "labels_as_tags": [<br>    "unset"<br>  ],<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {},<br>  "tenant": null<br>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br>Map of maps. Keys are names of descriptors. Values are maps of the form<br>`{<br>   format = string<br>   labels = list(string)<br>}`<br>(Type is `any` so the map values can later be enhanced to provide additional options.)<br>`format` is a Terraform format string to be passed to the `format()` function.<br>`labels` is a list of labels, in order, to pass to `format()` function.<br>Label values will be normalized before being passed to `format()` so they will be<br>identical to how they appear in `id`.<br>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | The name of the DynamoDB table. If not provided, the name will be generated from context. | `list(string)` | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | FOR TESTING ONLY! When set to true, `terraform destroy` will destroy the S3 buckets and all the objects in them.<br>These objects are not recoverable even if you have versioning or backups enabled. | `bool` | `false` | no |
| <a name="input_green_bucket_logging"></a> [green\_bucket\_logging](#input\_green\_bucket\_logging) | Destination for S3 Server Access Logs for the green bucket. | <pre>list(object({<br>    target_bucket = string<br>    target_prefix = string<br>  }))</pre> | `[]` | no |
| <a name="input_green_kms_key_arn"></a> [green\_kms\_key\_arn](#input\_green\_kms\_key\_arn) | The KMS Key ARN for encrypting object (SSE-KMS) in the green bucket. Default is to use default (SSE-S3) key. | `list(string)` | `[]` | no |
| <a name="input_green_s3_bucket_name"></a> [green\_s3\_bucket\_name](#input\_green\_s3\_bucket\_name) | S3 bucket name for bucket in green region. If not provided, the name will be generated from context. | `list(string)` | `[]` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for keep the existing setting, which defaults to `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br>Does not affect keys of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br>set as tag values, and output by this module individually.<br>Does not affect values of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br>Default is to include all labels.<br>Tags with empty values will not be included in the `tags` output.<br>Set to `[]` to suppress all generated tags.<br>**Notes:**<br>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_lock_table_enabled"></a> [lock\_table\_enabled](#input\_lock\_table\_enabled) | Set true to create a DynamoDB table to provide Terraform state locking. Highly recommended.<br>If replication is enabled, a global DynamoDB table will be created in both the blue and green regions. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br>This is the only ID element not also included as a `tag`.<br>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | The ARN of the policy that sets the permissions boundary for the IAM role used for replication. | `list(string)` | `[]` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br>Characters matching the regex will be removed from the ID elements.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_replication_enabled"></a> [replication\_enabled](#input\_replication\_enabled) | Set true to enable bidirectional replication and creation of hot standby for quick failover. Highly recommended.<br>If set to `false`, the "green" configuration will be ignored.<br>Replication is not supported in AWS GovCloud (US) because S3 Replication Time Control (S3 RTC) is not available. | `bool` | `true` | no |
| <a name="input_replication_role_name"></a> [replication\_role\_name](#input\_replication\_role\_name) | The name to give to the IAM role created for replication. If not provided, the name will be generated from context. | `list(string)` | `[]` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_blue_backend_config"></a> [blue\_backend\_config](#output\_blue\_backend\_config) | Backend configuration for the blue Terraform state |
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | (Deprecated, use `dynamodb_table_arns` instead) DynamoDB table ARN |
| <a name="output_dynamodb_table_arns"></a> [dynamodb\_table\_arns](#output\_dynamodb\_table\_arns) | Map (by region) of the ARNs for DynamoDB tables created by this module to store Terraform state locks.<br>Note that in general you should only refer to the tables by name and region, not by ARN. |
| <a name="output_dynamodb_table_id"></a> [dynamodb\_table\_id](#output\_dynamodb\_table\_id) | DynamoDB table ID |
| <a name="output_dynamodb_table_name"></a> [dynamodb\_table\_name](#output\_dynamodb\_table\_name) | DynamoDB table name |
| <a name="output_green_backend_config"></a> [green\_backend\_config](#output\_green\_backend\_config) | Backend configuration for the green Terraform state |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | (Deprecated, use `s3_bucket_arns` instead): S3 bucket ARN |
| <a name="output_s3_bucket_arns"></a> [s3\_bucket\_arns](#output\_s3\_bucket\_arns) | Map (by region) of the ARNs of the created S3 buckets |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | (Deprecated, use `s3_bucket_domains` instead): S3 bucket domain name |
| <a name="output_s3_bucket_domains"></a> [s3\_bucket\_domains](#output\_s3\_bucket\_domains) | Map (by region) of the domain names of the created S3 buckets |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | (Deprecated, use `s3_bucket_ids` instead): S3 bucket ID |
| <a name="output_s3_bucket_ids"></a> [s3\_bucket\_ids](#output\_s3\_bucket\_ids) | Map (by region) of the IDs (names) of the created S3 buckets |
| <a name="output_s3_bucket_kms_key_arns"></a> [s3\_bucket\_kms\_key\_arns](#output\_s3\_bucket\_kms\_key\_arns) | Map (by bucket name) of the ARNs of the KMS keys used to encrypt the created S3 buckets |
| <a name="output_sns_topic_arns"></a> [sns\_topic\_arns](#output\_sns\_topic\_arns) | Map (by region) of the ARNs for the SNS Topics created by this module to receive<br>replication event notifications regarding the created S3 bucket |
<!-- markdownlint-restore -->
