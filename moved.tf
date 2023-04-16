moved {
  from = aws_dynamodb_table.with_server_side_encryption
  to   = aws_dynamodb_table.locks
}

moved {
  from = aws_s3_bucket.default[0]
  to   = module.blue_bucket[0].aws_s3_bucket.each
}

moved {
  from = aws_s3_bucket_public_access_block.default[0]
  to   = module.blue_bucket[0].aws_s3_bucket_public_access_block.each
}
