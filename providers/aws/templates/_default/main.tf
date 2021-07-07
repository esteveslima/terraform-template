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

}

# Use "terraform init" to init project and get provider packages

# Customizable variables to use in resources, which will be propted for input before deploy
variable "<var_name>" {
  # description = 
  # default     = 
  # type        = 
  # sensitive   = 
}
# Use '... -var "<var_name> = <value>"' flag to set variables values directly without prompt for input 
# Use '... -var-file "<path_to_file.tfvars>"' flag to select a variable index file(may be useful to select different environments)

# Use "terraform plan" to view infrastructure changes to be applied with the code changes
resource "<provider>_<resource>" "<resource_name>" {
  # ...

  # tags = {
  #   Name = var.<var_name>
  # }
}
# Use "terraform apply" to deploy infrastructure in the cloud provider
# Use "terraform destroy" to remove infrastructure from the cloud provider
# Use "... -target <resource>" flag to select a single resource to be affected by the command, without having to change the code structure

# Generated .tfstate files are important to keep track of changes, removing them may cause sync problems
# Use "terraform state ..." to visualize information of deployed infrastructure

# Set Convenient outputs to visualize information from deployed resources
output "<some_output_name>" {

}
# Use "terraform refresh" to reset state and run outputs again, without having to deploy
