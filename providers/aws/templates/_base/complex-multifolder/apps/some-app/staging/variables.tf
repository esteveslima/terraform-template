# Variables declaration for module input, which can be used in other resources


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
