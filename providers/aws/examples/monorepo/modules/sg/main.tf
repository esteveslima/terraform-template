# Implementing security group as module
# Ease the configuration of security groups, publicly open or open for other security groups

locals {
  name        = var.name
  environment = var.environment
  protocol    = upper(var.protocol)
  description = var.description
  vpc_id      = var.vpc_id

  security_groups_ids = var.security_groups_ids
  inbound_sg_ports    = local.protocol == "-1" ? [0] : var.inbound_sg_ports
}


###############################   Data sources   ###############################






###############################   Application   ###############################



resource "aws_security_group" "security_group" {
  name_prefix = "${local.name}-${local.environment}-sg"
  description = "${local.description}[public open sg(${local.protocol})]"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = local.inbound_sg_ports
    content {
      description      = "(${local.protocol}) :${ingress.value} inbound"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = local.protocol
      cidr_blocks      = local.security_groups_ids != null ? null : ["0.0.0.0/0"]
      security_groups  = local.security_groups_ids
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name}-${local.environment}-sg"
  }
}
