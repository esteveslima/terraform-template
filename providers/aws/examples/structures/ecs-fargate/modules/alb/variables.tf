variable "alb_vpc_id" {
  description = "vpc id for alb"
  type        = string
}

variable "alb_subnets_ids" {
  description = "list of subnet ids for alb"
  type        = list(string)
}
