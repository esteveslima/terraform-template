##### Other required inherited values or resources

variable "name" {
  description = "sg name"
  type        = string
}

variable "environment" {
  description = "sg env"
  type        = string
}

variable "vpc_id" {
  description = "vpc for sg"
  type        = string
}



###############################   Module configurations   ###############################

variable "description" {
  description = "sg description"
  type        = string
  default     = ""
}

variable "security_groups_ids" {
  description = "security group ids(optional, for sg inbound)"
  type        = list(string)
  default     = null
}

variable "inbound_sg_ports" {
  description = "inbound ports for security group"
  type        = list(number)
  default     = [0]
}

variable "protocol" {
  description = "sg protocol"
  type        = string
  default     = "-1"
}
