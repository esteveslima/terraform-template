# Implementing ecs alb as module
# For costs saving it can be reused, using alongside multiple listeners and rules(especially in low traffic cases)
# For relibility it should be created one per service


locals {
  alb_vpc_id      = var.alb_vpc_id
  alb_subnets_ids = var.alb_subnets_ids
}


####################################################################################################



# Data sources



#



####################################################################################################



# Create the security group for lb
resource "aws_security_group" "example_security_group_lb" {
  name        = "example_security_group_lb"
  description = "Allow inbound http/https traffic and all outbound traffic"
  vpc_id      = local.alb_vpc_id

  ingress { // TODO: create dinamically from a set of ports variable
    description      = "allow http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "allow https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_lb"
  }
}

# Create the application load balancer
resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example_security_group_lb.id]
  subnets            = local.alb_subnets_ids

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Name = "example_lb"
  }
}



####################################################################################################



# Create the security group for the instances/tasks behind the lb
resource "aws_security_group" "example_security_group_lb_tasks_instances" {
  name        = "example_security_group_lb_tasks_instances"
  description = "Allow only outbound traffic"
  vpc_id      = local.alb_vpc_id

  # allow only load balancer traffic to secure the public instances/tasks(which subnets were created public to avoid costs with NAT)
  ingress {
    description     = "allow all inbound traffic from alb"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.example_security_group_lb.id] # from lb security group only    
  }

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_lb_tasks_instances"
  }
}
