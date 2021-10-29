# Module for fetching remote state from another projects
# It is configured to fetch the remote state on the single s3 bucket created as resource(backend-s3 project folder)


locals {
  name        = var.name
  environment = var.environment
  full_key    = var.full_key

  workspace_name       = "${local.name}-${local.environment}" # Assuming that the entire project is respecting the naming pattern [name]-[environment] for projects workspace names
  region               = "us-west-1"
  bucket               = "terraform-backend-bucket-2021"
  workspace_key_prefix = "terraform-projects-workspaces"
  state_file_name      = "terraform.tfstate"
}


###############################   Data sources   ###############################

##### Fetch remote state from s3 using data source

data "terraform_remote_state" "remote_state" {
  backend = "s3"
  config = {
    region = local.region
    bucket = local.bucket
    key    = local.full_key != null ? local.full_key : "${local.workspace_key_prefix}/${local.workspace_name}/${local.state_file_name}"
  }
}
