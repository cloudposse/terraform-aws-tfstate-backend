resource "aws_s3_bucket" "each" {
  bucket = var.bucket_name

  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "each" {
  bucket = aws_s3_bucket.each.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "each" {
  bucket = aws_s3_bucket.each.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# After you apply the bucket owner enforced setting for Object Ownership, ACLs are disabled for the bucket.
# See https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
resource "aws_s3_bucket_ownership_controls" "each" {
  bucket = aws_s3_bucket.each.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "each" {
  bucket = aws_s3_bucket.each.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = length(var.kms_key_arn) == 0 ? "AES256" : "aws:kms"
      kms_master_key_id = one(var.kms_key_arn[*])
    }
    # Bucket keys are unique per user per session. Since Terraform generally uses
    # a separate session for each update, bucket keys actually add overhead rather than reduce it.
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_logging" "each" {
  count = length(var.bucket_logging) > 0 ? 1 : 0

  bucket = aws_s3_bucket.each.id

  target_bucket = var.bucket_logging[0].target_bucket
  target_prefix = var.bucket_logging[0].target_prefix
}
