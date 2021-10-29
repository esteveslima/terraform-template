###############################   Module configurations   ###############################

variable "name" {
  description = "application name to fetch the remote state"
  type        = string
}

variable "environment" {
  description = "application env to fetch the remote state"
  type        = string
}

variable "full_key" {
  description = "optional full key to fetch"
  type        = string
  default     = null
}
