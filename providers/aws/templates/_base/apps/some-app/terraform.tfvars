# Default assignment file for variables declared
# For multiple configurations, select a different '.tfvars' file with ' ... -var-file "<path_to_file.tfvars>" ' flag
# Beware not to commit this file with sensible data(consider using it on .gitignore)


var_name = "foo"

profile = "aws-cloud" # (P.S.: For terraform-container the "default" aws profile is a dummy for safety reasons, check the /config folder)
region  = "us-east-1"
