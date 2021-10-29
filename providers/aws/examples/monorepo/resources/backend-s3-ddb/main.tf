# Create the S3 backend resources
# This code should only ease the single creation, it is not required to sync state

locals {
  backend_s3_bucket_name = var.backend_s3_bucket_name
  backend_ddb_table_name = var.backend_ddb_table_name
}

###############################   Data sources   ###############################







###############################   Application   ###############################


resource "aws_s3_bucket" "terraform_state" {
  bucket = local.backend_s3_bucket_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = local.backend_ddb_table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
