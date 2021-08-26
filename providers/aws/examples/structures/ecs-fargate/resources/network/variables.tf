variable "profile" {
  description = "aws credentials profile"
  type        = string
  default     = "default"
}

variable "region" {
  description = "aws region"
  type        = string
  default     = "us-east-1"
}

variable "cidr_vpc" {
  description = "cidr vpc"
  type        = string
  default     = "100.100.0.0/16" # 2^(32-16)-2 = 65534 available addresses(100.100.0.1 ~ 100.100.255.254) for the vpc
}

variable "cidr_subnet_1" {
  description = "cidr subnet 1"
  type        = string
  default     = "100.100.0.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.0.0 ~ 100.100.0.13) 
}

variable "cidr_subnet_2" {
  description = "cidr subnet 2"
  type        = string
  default     = "100.100.1.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.1.0 ~ 100.100.1.13) 
}
