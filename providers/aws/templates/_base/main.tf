terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

# Provider definitions
provider "aws" {
  profile = "aws-cloud" # select the credentials profile(the "default" aws profile for terraform-container is a dummy for safety reasons)
  # region = "us-east-1"
}

# Use "terraform init" to init project and get provider packages

# Use "terraform plan" to view infrastructure changes to be applied on deploy
resource "aws_<resource>" "resource_name" {
  # ...

  tags = {
    Name = var.var_name # Assigning created variable to a resource definition
  }
}
# Use "terraform apply" to deploy infrastructure in the cloud provider
# Use "terraform destroy" to remove infrastructure from the cloud provider
# Use "... -target <resource>" flag to select a single resource to be affected by the command, without having to change the code structure

# Generated .tfstate files are important to keep track of changes, removing them may cause sync problems
# Use "terraform show" to visualize information about the current deployed infrastructure
# Use "terraform state <subcommand>" to visualize advanced information about the state of the infrastructure


