terraform {
  # # Setting the remote backend environment that stores the infrastructure state in the a cloud provider(terraform cloud recommended)
  # # The infrastructure state should be saved on production environments, but a normal version control system may lead into sync problems    
  # # Using remote backend requires to login with "terraform login" command and to setup credentials for cloud provider remotelly
  # # Remove it to fallback to local backend and generate local(insecure) state files for development and testing
  # backend "remote" {
  #   organization = "existing_organization_name" # previously created on the provider cloud
  #   workspaces {
  #     name = "existing_workspace_name" # previously created on the provider cloud(?)
  #   }
  # }

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
  # # The AWS credentials profile can be selected directly or it could be mapped with a variable to multiple profiles representing multiple deployment environments
  # profile = "aws-cloud" (P.S.: For terraform-container the "default" aws profile is a dummy for safety reasons, check the /config folder)

  # region  = "us-east-1"
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
