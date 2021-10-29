terraform {
  backend "s3" {
    region               = "us-west-1"
    encrypt              = true
    dynamodb_table       = "terraform-backend-ddb-2021"
    bucket               = "terraform-backend-bucket-2021"
    workspace_key_prefix = "terraform-projects-workspaces"
    key                  = "terraform.tfstate" // "{bucket}/{workspace_key_prefix}/{workspace_name}/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }

  required_version = ">= 1.0.0"
}



// Basic values for use on resources
locals {
  // considering workspace pattern [name]-[environment]
  environment = split("-", terraform.workspace)[length(split("-", terraform.workspace)) - 1] // environment's name at last part of workspace's name
  project     = replace(terraform.workspace, "/(-${local.environment})/", "")                // project's name removing the environment from workspace's name
}



provider "aws" {
  # profile = var.profile
  region = var.region

  default_tags {
    tags = {
      "Environment" = local.environment
      "Project"     = local.project
    }
  }
}
