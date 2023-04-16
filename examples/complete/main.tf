
module "tfstate" {
  source = "../.."

  providers = {
    aws.blue  = aws
    aws.green = aws.green
  }

  force_destroy       = true
  lock_table_enabled  = true
  replication_enabled = true

  context = module.this.context
}
