# Implementing ecs with fargate

# TODO: split in modules

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

locals {

}



####################################################################################################



# Setup base network
# Create isolated network in the cloud(vpc)
resource "aws_vpc" "example_vpc" {
  cidr_block = "100.100.0.0/16" # 2^(32-16)-2 = 65534 available addresses(100.100.0.1 ~ 100.100.255.254) for the vpc

  tags = {
    Name = "example_vpc"
  }
}
# Create the internet entry point for the vpc
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
    Name = "example_igw"
  }
}



####################################################################################################



# Setup public az subnet in the vpc(with inbound and outbound traffic)
# Create public subnetworks inside the vpc in multiple AZs
resource "aws_subnet" "example_subnet_public_1" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "100.100.0.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.0.0 ~ 100.100.0.13) 
  # map_public_ip_on_launch = true             # assign a public ip to instances in this subnet
  availability_zone = "${var.region}b"

  tags = {
    Name = "example_subnet_public_1"
  }
}
resource "aws_subnet" "example_subnet_public_2" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "100.100.1.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.1.0 ~ 100.100.1.13) 
  # map_public_ip_on_launch = true             # assign a public ip to instances in this subnet
  availability_zone = "${var.region}c"

  tags = {
    Name = "example_subnet_public_2"
  }
}
# Create the route table for the public subnets(targeting internet gateway)
resource "aws_route_table" "example_route_table_public_subnet" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "example_route_table_public_subnet"
  }
}
# Associate the route table to the public subnets
resource "aws_route_table_association" "example_route_table_association_public_subnet_1" {
  subnet_id      = aws_subnet.example_subnet_public_1.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}
resource "aws_route_table_association" "example_route_table_association_public_subnet_2" {
  subnet_id      = aws_subnet.example_subnet_public_2.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}



####################################################################################################



# Setup ECS



# Create the security group for lb
resource "aws_security_group" "example_security_group_lb" {
  name        = "example_security_group_lb"
  description = "Allow inbound http/https traffic and all outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
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
  subnets            = [aws_subnet.example_subnet_public_1.id, aws_subnet.example_subnet_public_2.id]

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

# Create target group, which contains the running instances/tasks
resource "aws_lb_target_group" "example_target_group" {
  name     = "example-target-group"
  protocol = "HTTP"
  port     = 80

  target_type                   = "ip"
  load_balancing_algorithm_type = "round_robin" # "least_outstanding_requests" balance by load
  vpc_id                        = aws_vpc.example_vpc.id

  tags = {
    Name = "example_target_group"
  }
}
# Create the lb http listener, which can use action rules to route the traffic for the corret target group
resource "aws_lb_listener" "example_lb_listener" {
  load_balancer_arn = aws_lb.example_lb.arn
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

# Create the security group for the instances/tasks behind the lb
resource "aws_security_group" "example_security_group_tasks_instances" {
  name        = "example_security_group_tasks_instances"
  description = "Allow only outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  # allow only load balancer traffic to secure the public tasks(which subnets were created public to avoid costs with NAT)
  ingress {
    description     = "allow all inbound traffic"
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
    Name = "example_security_group_tasks_instances"
  }
}



# Create the docker images repository(ECR)
resource "aws_ecr_repository" "example_ecr_repository" {
  name                 = "example_ecr_repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "example_ecr_repository"
  }
}



# Create role for task definition
resource "aws_iam_role" "example_role_task_definition" {
  name = "example_role_task_definition"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "example_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ],
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Name = "example_role_task_definition"
  }
}
# Create a task definition for the example
resource "aws_ecs_task_definition" "example_ecs_task_definition" {
  family                   = "example_ecs_task_definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.example_role_task_definition.arn

  container_definitions = jsonencode([
    {
      name      = "example_ecs_service"
      image     = "${aws_ecr_repository.example_ecr_repository.repository_url}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  # volume {
  #   name      = "service-storage"
  #   host_path = "/ecs/service-storage"
  # }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-1b, us-west-1c]"
  # }

  tags = {
    Name = "example_ecs_task_definition"
  }
}



# Create ecs cluster
resource "aws_ecs_cluster" "example_ecs_cluster" {
  name               = "example_ecs_cluster"
  capacity_providers = ["FARGATE"]

  tags = {
    Name = "example_ecs_cluster"
  }
}

# Create a service in the cluster for task definition
resource "aws_ecs_service" "example_ecs_service" {
  name            = "example_ecs_service"
  cluster         = aws_ecs_cluster.example_ecs_cluster.id
  task_definition = aws_ecs_task_definition.example_ecs_task_definition.arn
  launch_type     = "FARGATE"                    # could be used capacity provider config(?)
  desired_count   = 1                            # initial count, further scaled by app autoscaling
  lifecycle { ignore_changes = [desired_count] } # ignore further lifecycle changes and preserve autoscaling desired count


  load_balancer {
    target_group_arn = aws_lb_target_group.example_target_group.arn
    container_name   = "example_ecs_service"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.example_subnet_public_1.id, aws_subnet.example_subnet_public_2.id]
    security_groups  = [aws_security_group.example_security_group_tasks_instances.id]
    assign_public_ip = true # security groups allow access only from load balancer
  }

  depends_on = [
    aws_lb.example_lb,
    # aws_lb_target_group.example_target_group,
    aws_lb_listener.example_lb_listener,
    aws_lb_listener_rule.example_lb_listener_rule
  ]
  tags = {
    Name = "example_ecs_service"
  }
}


# TODO: not working..?
# Create the autoscaling policies for the ecs cluster service, which create cloudwatch alarms to trigger autoscale acitons
resource "aws_appautoscaling_target" "example_appautoscaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.example_ecs_cluster.name}/${aws_ecs_service.example_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
}
resource "aws_appautoscaling_policy" "example_ecs_policy_memory" {
  name               = "example_scale_memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.example_appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.example_appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.example_appautoscaling_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 90 # %
    scale_in_cooldown  = 60 # sec
    scale_out_cooldown = 60 # sec
  }
}
resource "aws_appautoscaling_policy" "example_ecs_policy_cpu" {
  name               = "example_scale_cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.example_appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.example_appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.example_appautoscaling_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 15 # %
    scale_in_cooldown  = 60 # sec
    scale_out_cooldown = 60 # sec
  }
}
