terraform {
  # Backend stores the infrastructure state remotelly(Secure S3 Bucket recommended for AWS providers)
  # Remote backends must be created beforehand(create manually or by terraform)
  # Removing the backend defaults to "local", which generate state files locally(insecure)
  backend "s3" {
    profile        = "aws-cloud"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "backend-s3-ddb"
    bucket         = "backend-s3-bucket"
    key            = "template-base"      # Key for state in s3 bucket(has a prefix for workspaces)
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

# It's possible to define multiple providers and select individually in each resource
provider "aws" {
  profile = var.profile   # Parametrize aws credentials profile to switch between accounts with different environments
  region  = var.region
}

# Constants assignment
locals {
  local_name = "bar"
}

####################################################################################################

#Simple resource
resource "aws_sns_topic" "simple_sns_topic" {
  name = var.var_name

}

# Terraform registry module
module "simple_queue" {
  source  = "terraform-aws-modules/sqs/aws" # remote registry module
  version = "~> 2.0"

  name = local.local_name
}

# Custom module
module "fifo_queue" {
  source = "../../modules/sqs-fifo" # local module

  name = local.local_name
}
