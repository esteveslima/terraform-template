# variable "profile" {
#   description = "aws credentials profile"
#   type        = string
#   default     = "default"
# }

variable "region" {
  description = "aws region"
  type        = string
  default     = "us-east-1"
}

variable "inbound_ports" {
  description = "inbound ports for alb"
  type        = list(number)
}
