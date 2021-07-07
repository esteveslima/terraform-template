# Variables declaration file for terraform

# The variables will be prompted for input on terraform command
# Use ' terraform ... -var "<var_name> = <value>" ' flag to set a variable value directly without prompt for input 
# Use ' terraform ... -var-file "<path_to_file>.tfvars" ' flag to select a variable assignment file (defaults to terraform.tfvars and may be useful to parametrize multiple environments/configurations)



variable "var_name" {
  # description = "some_description"
  # default     = "value"
  # type        = String
  # sensitive   = false
}

# variable "var2_name" {
#   # description = "some_description"
#   # default     = "value"
#   # type        = String
#   # sensitive   = false
# }
