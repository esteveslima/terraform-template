##### Other required inherited values or resources

variable "name" {
  description = "codebuild project name"
  type        = string
}

variable "environment" {
  description = "codebuild project env"
  type        = string
}

variable "bucket_arn" {
  description = "arn from bucket reserved for cache/logs/artifacts"
  type        = string
}

variable "bucket_name" {
  description = "name from bucket reserved for cache/logs/artifacts"
  type        = string
}

# variable "ecr_repository_name" {
#   description = "ecr repository name"
#   type        = string
# }

# variable "ecs_container_name" {
#   description = "ecs container name"
#   type        = string
# }



###############################   Module configurations   ###############################

variable "source_repository" {
  description = "source repository(github) name"
  type        = string
}

variable "build_env_vars" {
  description = "environment variables for build"
  type        = map(string)
  default     = {}
}

variable "inline_policy" {
  description = "optional single extra JSON policy for codebuild role"
  type        = string
  default     = null
}


