##### Other required inherited values or resources

variable "name" {
  type = string
}
variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "vpc for alb"
  type        = string
}

variable "subnets_ids" {
  description = "subnets ids for alb"
  type        = list(string)
}



###############################   Module configurations   ###############################

variable "internal" {
  description = "whether the alb is private(would also required to be in a private subnet)"
  type        = bool
  default     = false
}


variable "inbound_ports" {
  description = "inbound ports for alb security group"
  type        = list(number)
  default     = [80] // currently only create http listener
  validation {
    condition     = contains(var.inbound_ports, 80)
    error_message = "HTTP port required(currently only create http listener)."
  }
}
