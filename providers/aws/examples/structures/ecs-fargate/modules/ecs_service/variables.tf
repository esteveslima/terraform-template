variable "ecr_url" {
  description = "task definition ecr"
  type        = string
}

variable "ecs_cluster_id" {
  description = "service cluster"
  type        = string
}

variable "tg_arn" {
  description = "service target group"
  type        = string
}

variable "ecs_subnets_ids" {
  description = "list of subnet ids for ecs"
  type        = list(string)
}

variable "ecs_service_sg_id" {
  description = "service security group(from alb)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ecs cluster name"
  type        = string
}

