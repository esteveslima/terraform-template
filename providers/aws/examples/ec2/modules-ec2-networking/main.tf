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

# local constant assignment for usage in resources
locals {
  instance_1 = "example_instance_1"
  instance_2 = "example_instance_2"
}

module "basic_instance_ec2_1" {
  source = "./modules/ec2-basic-networking"

  instance_tag = local.instance_1
}

module "basic_instance_ec2_2" {
  source = "./modules/ec2-basic-networking"

  instance_tag = local.instance_2
}
