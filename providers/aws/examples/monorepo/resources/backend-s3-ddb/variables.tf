# variable "profile" {
#   description = "aws credentials profile"
#   type        = string
#   default     = "default"
# }

variable "region" {
  description = "aws region"
  type        = string
}

variable "backend_s3_bucket_name" {
  description = "bucket created for backend state"
  type        = string
}

variable "backend_ddb_table_name" {
  description = "state lock dynamodb table for backend state"
  type        = string
}
