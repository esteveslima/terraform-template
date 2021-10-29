##### Other required inherited values or resources

variable "name" {
  type = string
}
variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "vpc id for alb"
  type        = string
}

variable "listener_arn" {
  description = "lb listener arn to create the rules"
  type        = string
}



###############################   Module configurations   ###############################

variable "inbound_port" {
  description = "inbound port for tg"
  type        = number
}

variable "methods" {
  description = "listener rule methods to access the tg"
  type        = list(string)
  default     = []
}
variable "path" {
  description = "listener rule path to access the tg(basically the route for the service)"
  type        = string
}
