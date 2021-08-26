# Implementing ecs alb target group and listener


locals {
  tg_vpc_id = var.tg_vpc_id
  alb_arn   = var.alb_arn
}


####################################################################################################



# Data sources



#



####################################################################################################


# Create target group, which contains the running instances/tasks
resource "aws_lb_target_group" "example_target_group" {
  name     = "example-target-group"
  protocol = "HTTP"
  port     = 80

  target_type                   = "ip"
  load_balancing_algorithm_type = "round_robin" # "least_outstanding_requests" balance by load
  vpc_id                        = local.tg_vpc_id

  tags = {
    Name = "example_target_group"
  }
}
# Create the lb http listener, which can use action rules to route the traffic for the corret target group
resource "aws_lb_listener" "example_lb_listener" {
  # load_balancer_arn = aws_lb.example_lb.arn
  load_balancer_arn = local.alb_arn
  port              = "80"
  protocol          = "HTTP"

  # Action performed when no rules are matched/specified
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Default LB action with fixed response, use '/tasks' path to reach the target group for the ecs example</h1>"
      status_code  = "404"
    }
  }

  tags = {
    Name = "example_lb_listener"
  }
}
# Create the rules for the lb listener, with conditions to match the target group(similar to a reverse proxy)
resource "aws_lb_listener_rule" "example_lb_listener_rule" {
  listener_arn = aws_lb_listener.example_lb_listener.arn
  # priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_target_group.arn
  }

  condition {
    http_request_method {
      values = ["GET"]
    }
  }

  condition {
    path_pattern {
      values = ["*/tasks*"] # any path containing "tasks"
    }
  }

  tags = {
    Name = "example_lb_listener_rule"
  }
}
