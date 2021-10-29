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

variable "cidr_vpc" {
  description = "cidr vpc"
  type        = string
}

variable "cidr_subnet_public_1" {
  description = "cidr subnet public 1"
  type        = string
}

variable "cidr_subnet_public_2" {
  description = "cidr subnet public 2"
  type        = string
}

variable "cidr_subnet_private_1" {
  description = "cidr subnet private 1"
  type        = string
}

variable "cidr_subnet_private_2" {
  description = "cidr subnet private 2"
  type        = string
}
