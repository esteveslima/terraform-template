variable "git_repository" {
  description = "project's repository name"
  type        = string
}


variable "bucket_pipeline" {
  description = "bucket reserved for pipeline"
  # type        = string                      # entire resource as input
}

variable "ecs_container_name" {
  description = "ecs container name"
  type        = string
}

variable "ecr_repository_name" {
  description = "ecr repository name"
  type        = string
}

