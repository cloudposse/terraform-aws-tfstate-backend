locals {
  lock_table_enabled = local.enabled && var.lock_table_enabled
}
# All DynamoDB tables are now encrypted at rest by default. No need to set this explicitly.
# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table#server_side_encryption
resource "aws_dynamodb_table" "locks" {
  count = local.lock_table_enabled ? 1 : 0

  provider = aws.blue

  name = length(var.dynamodb_table_name) > 0 ? var.dynamodb_table_name[0] : module.dynamodb_label.id

  # PAY_PER_REQUEST is the recommended billing mode for Global (Replicated) Tables.
  # The Terraform lock table is very low traffic, so it's a good candidate for PAY_PER_REQUEST anyway.
  billing_mode = "PAY_PER_REQUEST"
  # Streams are required for Global Tables.
  stream_enabled   = var.replication_enabled
  stream_view_type = var.replication_enabled ? "NEW_AND_OLD_IMAGES" : null

  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  dynamic "replica" {
    for_each = var.replication_enabled ? [true] : []
    content {
      region_name            = local.green_region
      point_in_time_recovery = true
    }
  }

  tags = module.dynamodb_label.tags

  # Recommended lifecycle rules. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
  lifecycle { ignore_changes = [replica] }
}

