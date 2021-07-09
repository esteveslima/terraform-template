# Create the S3 backend resources

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

######################################################################################################

variable "profile" {
  description = "aws credentials profile"
  type        = string
  sensitive   = false
  # default     = 
}

variable "region" {
  description = "default region"
  type        = string
  sensitive   = false
  # default     = 
}

variable "backend_s3_bucket" {
  description = "bucket created for backend state"
  type        = string
  sensitive   = false
  # default     = 
}

variable "backend_s3_bucket_key" {
  description = "bucket key for created for backend state"
  type        = string
  sensitive   = false
  # default     = 
}

variable "backend_ddb_table" {
  description = "dynamodb table for created for backend state lock"
  type        = string
  sensitive   = false
  # default     = 
}

######################################################################################################

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.backend_s3_bucket

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.backend_ddb_table
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
