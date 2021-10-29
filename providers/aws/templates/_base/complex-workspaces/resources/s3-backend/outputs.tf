output "backend_s3_bucket" {
  description = "state bucket name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "backend_ddb_table" {
  description = "state lock table name"
  value       = aws_dynamodb_table.terraform_state_lock.name
}
