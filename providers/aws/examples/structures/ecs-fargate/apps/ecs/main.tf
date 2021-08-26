# Implementing ecs with fargate
# https://dev.to/kieranjen/ecs-fargate-service-auto-scaling-with-terraform-2ld
# https://towardsaws.com/aws-ecs-service-autoscaling-terraform-included-d4b46997742b

# TODO: split in modules ->
# TODO: parametrize modules to avoid name/config collisions, they were built statically

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

####################################################################################################



locals {

}



####################################################################################################

# Data sources

data "aws_vpc" "example_data_source_vpc" {
  tags = {
    Name = "example_vpc"
  }
}

data "aws_subnet" "example_data_source_subnet_1" {
  vpc_id = data.aws_vpc.example_data_source_vpc.id
  tags = {
    Name = "example_subnet_public_1"
  }
}
data "aws_subnet" "example_data_source_subnet_2" {
  vpc_id = data.aws_vpc.example_data_source_vpc.id
  tags = {
    Name = "example_subnet_public_2"
  }
}



####################################################################################################



# Setup ECS



# # Create the security group for lb
# resource "aws_security_group" "example_security_group_lb" {
#   name        = "example_security_group_lb"
#   description = "Allow inbound http/https traffic and all outbound traffic"
#   vpc_id      = data.aws_vpc.example_data_source_vpc.id

#   ingress {
#     description      = "allow http"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }
#   ingress {
#     description      = "allow https"
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   egress {
#     description      = "allow all outbound traffic"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "example_security_group_lb"
#   }
# }
# # Create the application load balancer
# resource "aws_lb" "example_lb" {
#   name               = "example-lb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.example_security_group_lb.id]
#   subnets            = [data.aws_subnet.example_data_source_subnet_1.id, data.aws_subnet.example_data_source_subnet_2.id]

#   enable_deletion_protection = false

#   # access_logs {
#   #   bucket  = aws_s3_bucket.lb_logs.bucket
#   #   prefix  = "test-lb"
#   #   enabled = true
#   # }

#   tags = {
#     Name = "example_lb"
#   }
# }

# # Create the security group for the instances/tasks behind the lb
# resource "aws_security_group" "example_security_group_lb_tasks_instances" {
#   name        = "example_security_group_lb_tasks_instances"
#   description = "Allow only outbound traffic"
#   vpc_id      = data.aws_vpc.example_data_source_vpc.id

#   # allow only load balancer traffic to secure the public tasks(which subnets were created public to avoid costs with NAT)
#   ingress {
#     description     = "allow all inbound traffic from alb"
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     security_groups = [aws_lb.example_lb.example_security_group_lb] # from lb security group only    
#   }

#   egress {
#     description      = "allow all outbound traffic"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "example_security_group_lb_tasks_instances"
#   }
# }

module "example_alb" {
  source = "../../modules/alb"

  alb_vpc_id      = data.aws_vpc.example_data_source_vpc.id
  alb_subnets_ids = [data.aws_subnet.example_data_source_subnet_1.id, data.aws_subnet.example_data_source_subnet_2.id]
}



# # Create target group, which contains the running instances/tasks
# resource "aws_lb_target_group" "example_target_group" {
#   name     = "example-target-group"
#   protocol = "HTTP"
#   port     = 80

#   target_type                   = "ip"
#   load_balancing_algorithm_type = "round_robin" # "least_outstanding_requests" balance by load
#   vpc_id                        = data.aws_vpc.example_data_source_vpc.id

#   tags = {
#     Name = "example_target_group"
#   }
# }
# # Create the lb http listener, which can use action rules to route the traffic for the corret target group
# resource "aws_lb_listener" "example_lb_listener" {
#   # load_balancer_arn = aws_lb.example_lb.arn
#   load_balancer_arn = module.example_alb.alb_arn
#   port              = "80"
#   protocol          = "HTTP"

#   # Action performed when no rules are matched/specified
#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/html"
#       message_body = "<h1>Default LB action with fixed response, use '/tasks' path to reach the target group for the ecs example</h1>"
#       status_code  = "404"
#     }
#   }

#   tags = {
#     Name = "example_lb_listener"
#   }
# }
# # Create the rules for the lb listener, with conditions to match the target group(similar to a reverse proxy)
# resource "aws_lb_listener_rule" "example_lb_listener_rule" {
#   listener_arn = aws_lb_listener.example_lb_listener.arn
#   # priority     = 1

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.example_target_group.arn
#   }

#   condition {
#     http_request_method {
#       values = ["GET"]
#     }
#   }

#   condition {
#     path_pattern {
#       values = ["*/tasks*"] # any path containing "tasks"
#     }
#   }

#   tags = {
#     Name = "example_lb_listener_rule"
#   }
# }

module "example_alb_tg_listener" {
  source = "../../modules/alb_tg_listener"

  tg_vpc_id = data.aws_vpc.example_data_source_vpc.id
  alb_arn   = module.example_alb.alb_arn
}



# # Create the docker images repository(ECR)
# resource "aws_ecr_repository" "example_ecr_repository" {
#   name                 = "example_ecr_repository"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   tags = {
#     Name = "example_ecr_repository"
#   }
# }

module "example_ecr" {
  source = "../../modules/ecr"

}



# # Create ecs cluster
# resource "aws_ecs_cluster" "example_ecs_cluster" {
#   name               = "example_ecs_cluster"
#   capacity_providers = ["FARGATE"]

#   tags = {
#     Name = "example_ecs_cluster"
#   }
# }

module "example_ecs_cluster" {
  source = "../../modules/ecs_cluster"

}



# # Create role for task definition
# resource "aws_iam_role" "example_role_task_definition" {
#   name = "example_role_task_definition"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       },
#     ]
#   })

#   inline_policy {
#     name = "example_inline_policy"

#     policy = jsonencode({
#       Version = "2012-10-17",
#       Statement = [
#         // ECR
#         {
#           Effect = "Allow",
#           Action = [
#             "ecr:GetAuthorizationToken",
#             "ecr:BatchCheckLayerAvailability",
#             "ecr:GetDownloadUrlForLayer",
#             "ecr:BatchGetImage"
#           ],
#           Resource = "*"
#         },
#         // Autoscaling
#         {
#           Effect = "Allow",
#           Action = [
#             "application-autoscaling:*",
#             "ecs:DescribeServices",
#             "ecs:UpdateService",
#             "cloudwatch:DescribeAlarms",
#             "cloudwatch:PutMetricAlarm",
#             "cloudwatch:DeleteAlarms",
#             "cloudwatch:DescribeAlarmHistory",
#             "cloudwatch:DescribeAlarms",
#             "cloudwatch:DescribeAlarmsForMetric",
#             "cloudwatch:GetMetricStatistics",
#             "cloudwatch:ListMetrics",
#             "cloudwatch:PutMetricAlarm",
#             "cloudwatch:DisableAlarmActions",
#             "cloudwatch:EnableAlarmActions",
#             "iam:CreateServiceLinkedRole",
#             "sns:CreateTopic",
#             "sns:Subscribe",
#             "sns:Get*",
#             "sns:List*"
#           ],
#           Resource = "*"
#         },
#         //ECS
#         {
#           Effect = "Allow",
#           Action = [
#             "ec2:DescribeTags",
#             "ecs:DeregisterContainerInstance",
#             "ecs:DiscoverPollEndpoint",
#             "ecs:Poll",
#             "ecs:RegisterContainerInstance",
#             "ecs:StartTelemetrySession",
#             "ecs:UpdateContainerInstancesState",
#             "ecs:Submit*",
#             "logs:CreateLogGroup",
#             "logs:CreateLogStream",
#             "logs:PutLogEvents"
#           ],
#           Resource = "*"
#         },
#       ]
#     })
#   }

#   tags = {
#     Name = "example_role_task_definition"
#   }
# }
# # Create a task definition for the example
# resource "aws_ecs_task_definition" "example_ecs_task_definition" {
#   family                   = "example_ecs_task_definition"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = 256
#   memory                   = 512
#   execution_role_arn       = aws_iam_role.example_role_task_definition.arn
#   task_role_arn            = aws_iam_role.example_role_task_definition.arn

#   container_definitions = jsonencode([
#     {
#       name      = "example_ecs_container"
#       image     = "${module.example_ecr.ecr_repository_url}"
#       cpu       = 256
#       memory    = 512
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#         }
#       ]
#     }
#   ])

#   # volume {
#   #   name      = "service-storage"
#   #   host_path = "/ecs/service-storage"
#   # }

#   # placement_constraints {
#   #   type       = "memberOf"
#   #   expression = "attribute:ecs.availability-zone in [us-west-1b, us-west-1c]"
#   # }

#   tags = {
#     Name = "example_ecs_task_definition"
#   }
# }



# # Create a service in the cluster for task definition
# resource "aws_ecs_service" "example_ecs_service" {
#   name            = "example_ecs_service"
#   cluster         = module.example_ecs_cluster.ecs_cluster_id
#   task_definition = aws_ecs_task_definition.example_ecs_task_definition.arn
#   launch_type     = "FARGATE"                    # could also be used capacity provider config(?)
#   desired_count   = 1                            # initial count, further scaled by app autoscaling
#   lifecycle { ignore_changes = [desired_count] } # ignore further lifecycle changes and preserve autoscaling desired count


#   load_balancer {
#     target_group_arn = module.example_alb_tg_listener.tg_arn
#     container_name   = "example_ecs_container"
#     container_port   = 80
#   }

#   network_configuration {
#     subnets          = [data.aws_subnet.example_data_source_subnet_1.id, data.aws_subnet.example_data_source_subnet_2.id]
#     security_groups  = [module.example_alb.alb_security_group_tasks_instances_id]
#     assign_public_ip = true # security groups allow access only from load balancer
#   }

#   depends_on = [
#     module.example_alb,
#     module.example_alb_tg_listener
#   ]
#   tags = {
#     Name = "example_ecs_service"
#   }
# }



# # Create role for autoscaling target
# resource "aws_iam_role" "example_role_autoscaling_target" {
#   name = "example_role_autoscaling_target"

#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Action" : "sts:AssumeRole"
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "application-autoscaling.amazonaws.com"
#         },
#       }
#     ]
#   })

#   tags = {
#     Name = "example_role_autoscaling_target"
#   }
# }
# resource "aws_iam_policy_attachment" "example_role_autoscaling_target_native_policy_attachment" {
#   name       = "example_role_autoscaling_target_native_policy_attachment"
#   roles      = ["${aws_iam_role.example_role_autoscaling_target.id}"]
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
# }

# # Create the autoscaling policies for the ecs cluster service, which create cloudwatch alarms to trigger autoscale acitons
# resource "aws_appautoscaling_target" "example_appautoscaling_target" {
#   service_namespace  = "ecs"
#   resource_id        = "service/${module.example_ecs_cluster.ecs_cluster_name}/${aws_ecs_service.example_ecs_service.name}"
#   role_arn           = aws_iam_role.example_role_autoscaling_target.arn
#   scalable_dimension = "ecs:service:DesiredCount"
#   min_capacity       = 0
#   max_capacity       = 3
# }
# resource "aws_appautoscaling_policy" "example_ecs_policy_memory" {
#   name               = "example_scale_memory"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.example_appautoscaling_target.service_namespace
#   resource_id        = aws_appautoscaling_target.example_appautoscaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.example_appautoscaling_target.scalable_dimension

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }

#     target_value       = 90.0 # %
#     scale_in_cooldown  = 60   # sec
#     scale_out_cooldown = 60   # sec
#   }

#   depends_on = [aws_appautoscaling_target.example_appautoscaling_target]
# }
# resource "aws_appautoscaling_policy" "example_ecs_policy_cpu" {
#   name               = "example_scale_cpu"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.example_appautoscaling_target.service_namespace
#   resource_id        = aws_appautoscaling_target.example_appautoscaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.example_appautoscaling_target.scalable_dimension

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }

#     target_value       = 90.0 # %
#     scale_in_cooldown  = 60   # sec
#     scale_out_cooldown = 60   # sec
#   }

#   depends_on = [aws_appautoscaling_target.example_appautoscaling_target]
# }

module "example_ecs_service" {
  source = "../../modules/ecs_service"

  ecr_url           = module.example_ecr.ecr_repository_url
  ecs_cluster_name  = module.example_ecs_cluster.ecs_cluster_name
  ecs_cluster_id    = module.example_ecs_cluster.ecs_cluster_id
  tg_arn            = module.example_alb_tg_listener.tg_arn
  ecs_subnets_ids   = [data.aws_subnet.example_data_source_subnet_1.id, data.aws_subnet.example_data_source_subnet_2.id]
  ecs_service_sg_id = module.example_alb.alb_security_group_tasks_instances_id
}
