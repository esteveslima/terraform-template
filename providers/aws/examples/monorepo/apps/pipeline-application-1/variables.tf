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

variable "source_repository" {
  description = "pipeline repository"
  type        = string
}
variable "source_repository_branch" {
  description = "pipeline repository branch"
  type        = string
}

variable "inline_policy_codebuild_json_file" {
  type        = string
  default     = null
  description = "application extra policy for codebuild"
}

variable "inline_policy_codepipeline_json_file" {
  type        = string
  default     = null
  description = "application extra policy for codepipeline"
}
