terraform {
  backend "s3" {
    profile        = "aws-cloud"
    region         = "us-east-1"
    bucket         = "backend-s3-bucket"
    key            = "backend-s3-bucket-key"
    dynamodb_table = "backend-s3-ddb"
    encrypt        = true
  }

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
