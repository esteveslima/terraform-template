# Implementing ecs alb as module with its listeners
# It creates a security group to use on applications, allowing inbloud from the alb

# For costs saving it can be reused, using with multiple listeners and rules(especially in low traffic cases)
# For relibility it should be created one per service



locals {
  name        = var.name
  environment = var.environment
  vpc_id      = var.vpc_id
  subnets_ids = var.subnets_ids

  internal      = var.internal
  inbound_ports = var.inbound_ports
}


###############################   Data sources   ###############################






###############################   Application   ###############################



##### Security groups

# Create the security group for lb (a common SG policy like this could be created independently and fetched with data source)

module "sg_alb" {
  source = "../sg"

  name        = local.name
  environment = local.environment
  vpc_id      = local.vpc_id

  protocol         = "TCP"
  inbound_sg_ports = local.inbound_ports
}

# Create the security group for the applications behind the lb

module "sg_applications_alb" {
  source = "../sg"

  name        = local.name
  environment = local.environment
  vpc_id      = local.vpc_id // maybe get the vpc from alb?

  # allow only load balancer traffic to secure the public instances/tasks(which subnets were created public to avoid costs with NAT)
  security_groups_ids = [module.sg_alb.sg.id] # wide open for lb security group only   

  depends_on = [module.sg_alb]
}



##### Application load balancer

resource "aws_lb" "alb" {
  name               = "${local.name}-${local.environment}-alb"
  internal           = local.internal
  load_balancer_type = "application"
  security_groups    = [module.sg_alb.sg.id]
  subnets            = local.subnets_ids

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Name = "${local.name}-${local.environment}-alb"
  }
}



##### ALB listener, which can use action rules to route the traffic for the corret target group
// currently only create http listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  protocol          = "HTTP"
  port              = 80

  # Action performed when no rules are matched/specified
  default_action {
    type = "fixed-response"

    fixed_response {
      status_code  = "404"
      content_type = "text/html"
      message_body = "<h1>Please specify the path for the ${local.environment} service</h1>"
    }
  }

  tags = {
    Name = "${local.name}-${local.environment}-alb-listener"
  }
}
