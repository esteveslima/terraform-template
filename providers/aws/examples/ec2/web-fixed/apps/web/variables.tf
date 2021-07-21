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

variable "instance_ami" {
  description = "example instance ami"
  type        = string
  default     = "ami-0dc2d3e4c0f9ebd18"
}
