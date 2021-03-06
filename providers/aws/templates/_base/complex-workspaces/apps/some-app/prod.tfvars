# Assignment file for prod environment using terraform workspaces
# Beware not to commit this file with sensible data(consider using it on .gitignore)

# Select workspace with "terraform workspace select prod" before using this file with '... -var-file prod.tfvars' flag in a terraform command


var_name = "baz-complex-workspaces"    # changing one parameter for this specific environment

profile = "aws-cloud" # (P.S.: For terraform-container the "default" aws profile is a dummy for safety reasons, check the /config folder)
region  = "us-east-1"
