Desired infrastructure constructions for applications

# This template is suited for managing different environments using terraform workspaces
# Select the desired environment with terraform workspace command and select the correct .tfvars file when making changes to the infrastructure
### use "... -var-file=$(terraform workspace show).tfvars" to automatically select the current workspace