variable "tg_vpc_id" {
  description = "vpc id for alb"
  type        = string
}

variable "alb_arn" {
  description = "alb arn to create the listener"
  type        = string
}
