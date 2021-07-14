# Variables declaration for module input, which can be used in other resources
# The variables will be prompted for input on terraform command if not provided by '-var' or '-var-file' flag

# TODO: change constant variables to locals
# better name would be input.tf because those are the input for the module(root or leaf)

variable "var_name" {
  description = "some variable"
  type        = string
}

variable "profile" {
  description = "aws credentials profile"
  type        = string
  default     = "default"
}

variable "region" {
  description = "default region"
  type        = string
}
