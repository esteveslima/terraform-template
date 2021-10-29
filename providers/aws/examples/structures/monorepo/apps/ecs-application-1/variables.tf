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



variable "task_port" {
  type        = number
  description = "application entry port"
}
variable "task_env_vars" {
  type        = map(string)
  description = "application environment variables"
}
variable "inline_policy_json_file" {
  type        = string
  default     = null
  description = "application extra policy for task"
}
variable "task_cpu" {
  type        = number
  description = "application cpu"
}
variable "task_memory" {
  type        = number
  description = "application memory"
}
variable "autoscaling_min_tasks" {
  type        = number
  description = "application min number of replicas"
}
variable "autoscaling_max_tasks" {
  type        = number
  description = "application max number of replicas"
}
variable "autoscaling_target_cpu" {
  type        = number
  description = "application target percentage of average cpu usage across tasks"
}
variable "autoscaling_target_memory" {
  type        = number
  description = "application target percentage of average memory usage across tasks"
}
