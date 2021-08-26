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

variable "git_repository" {
  description = "pipeline repository"
  type        = string
}

variable "git_branch" {
  description = "pipeline repository branch"
  type        = string
}
