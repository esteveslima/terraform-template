##### Other required inherited values or resources

variable "name" {
  description = "codestar name"
  type        = string
}

variable "environment" {
  description = "codestar env"
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

variable "codesource_arn" {
  description = "codesource(codestar) arn"
  type        = string
}

variable "codebuild_project_name" {
  description = "codebuild name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ecs cluster name"
  type        = string
  default     = null
}

variable "ecs_service_name" {
  description = "ecs service name"
  type        = string
  default     = null
}


###############################   Module configurations   ###############################

variable "source_repository" {
  description = "source repository(github) name"
  type        = string
}

variable "source_repository_branch" {
  description = "source repository(github) branch"
  type        = string
}

variable "inline_policy" {
  description = "optional single extra JSON policy for codepipeline role"
  type        = string
  default     = null
}
