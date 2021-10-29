# Implementing target group and listerner rules for lb



locals {
  name         = var.name
  environment  = var.environment
  vpc_id       = var.vpc_id
  listener_arn = var.listener_arn

  inbound_port = var.inbound_port
  methods      = var.methods
  path         = var.path
}


###############################   Data sources   ###############################






###############################   Application   ###############################



##### Target group, which contains the running applications on instances/tasks
resource "aws_lb_target_group" "tg" {
  name     = "${local.name}-${local.environment}-tg"
  protocol = "HTTP"
  port     = local.inbound_port

  target_type                   = "ip"
  load_balancing_algorithm_type = "round_robin" # "least_outstanding_requests" balance by load
  vpc_id                        = local.vpc_id

  tags = {
    Name = "${local.name}-${local.environment}-tg"
  }
}

# Rules for the lb listener, with conditions to match the target group(similar to a reverse proxy)
resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = local.listener_arn
  # priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    http_request_method {
      values = [for method in local.methods : upper(method)]
    }
  }

  condition {
    path_pattern {
      values = ["${local.path}"]
    }
  }

  tags = {
    Name = "${local.name}-${local.environment}-listener-rule"
  }
}
