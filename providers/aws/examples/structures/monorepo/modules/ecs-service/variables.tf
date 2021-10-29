##### Other required inherited values or resources

variable "name" {
  description = "ecs service name"
  type        = string
}

variable "environment" {
  description = "ecs service env"
  type        = string
}

variable "region" {
  description = "aws region"
  type        = string
}

variable "tg_arn" {
  description = "service target group"
  type        = string
}

variable "subnets_ids" {
  description = "list of subnet ids for ecs"
  type        = list(string)
}

variable "ecs_service_sg_id" {
  description = "service security group(from alb)"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "service cluster"
  type        = string
}
variable "ecs_cluster_name" {
  description = "ecs cluster name"
  type        = string
}

variable "ecr_url" {
  description = "task definition ecr"
  type        = string
}



###############################   Module configurations   ###############################

variable "task_port" {
  description = "task port"
  type        = number
}
variable "task_command" {
  description = "task command"
  type        = string
  default     = ""
}
variable "task_env_vars" {
  description = "task environment variables"
  type        = map(string)
  default     = {}
}
variable "task_secret_vars" {
  description = "task secrets"
  type        = map(string)
  validation {
    condition     = alltrue([for secret in var.task_secret_vars : substr(secret.value, 0, 22) == "arn:aws:secretsmanager:"])
    error_message = "Secrets values must be valid ARNs."
  }
  default = {}
}

variable "task_cpu" {
  description = "task cpu"
  type        = number
  default     = 256
}
variable "task_memory" {
  description = "task memory"
  type        = number
  default     = 512
}

variable "autoscaling_min_tasks" {
  description = "minimum number of tasks running"
  type        = number
  default     = 1
}
variable "autoscaling_max_tasks" {
  description = "maximum number of tasks running"
  type        = number
  default     = 1
}

variable "autoscaling_target_cpu" {
  description = "target(%) threshold of cpu usage for autoscaling"
  type        = number
  default     = 90.0 # %
}
variable "autoscaling_target_memory" {
  description = "target(%) threshold of memory usage for autoscaling"
  type        = number
  default     = 90.0 # %
}

variable "inline_policy" {
  description = "optional single extra JSON policy for task role"
  type        = string
  default     = null
}
