# Implementing ecs alb as module
# For costs saving it can be reused, using alongside multiple listeners and rules(especially in low traffic cases)
# For relibility it should be created one per service


locals {
  ecr_url           = var.ecr_url
  ecs_cluster_name  = var.ecs_cluster_name
  ecs_cluster_id    = var.ecs_cluster_id
  tg_arn            = var.tg_arn
  ecs_subnets_ids   = var.ecs_subnets_ids
  ecs_service_sg_id = var.ecs_service_sg_id
}


####################################################################################################



# Data sources



#



####################################################################################################


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
        // ECR
        {
          Effect = "Allow",
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ],
          Resource = "*"
        },
        // Autoscaling
        {
          Effect = "Allow",
          Action = [
            "application-autoscaling:*",
            "ecs:DescribeServices",
            "ecs:UpdateService",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DescribeAlarmHistory",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:DescribeAlarmsForMetric",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DisableAlarmActions",
            "cloudwatch:EnableAlarmActions",
            "iam:CreateServiceLinkedRole",
            "sns:CreateTopic",
            "sns:Subscribe",
            "sns:Get*",
            "sns:List*"
          ],
          Resource = "*"
        },
        //ECS
        {
          Effect = "Allow",
          Action = [
            "ec2:DescribeTags",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:UpdateContainerInstancesState",
            "ecs:Submit*",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "*"
        },
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
  task_role_arn            = aws_iam_role.example_role_task_definition.arn

  container_definitions = jsonencode([
    {
      name      = "example_ecs_container"
      image     = "${local.ecr_url}"
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



# Create a service in the cluster for task definition
resource "aws_ecs_service" "example_ecs_service" {
  name            = "example_ecs_service"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.example_ecs_task_definition.arn
  launch_type     = "FARGATE"                    # could also be used capacity provider config(?)
  desired_count   = 1                            # initial count, further scaled by app autoscaling
  lifecycle { ignore_changes = [desired_count] } # ignore further lifecycle changes and preserve autoscaling desired count


  load_balancer {
    target_group_arn = local.tg_arn
    container_name   = "example_ecs_container"
    container_port   = 80
  }

  network_configuration {
    subnets          = local.ecs_subnets_ids
    security_groups  = [local.ecs_service_sg_id]
    assign_public_ip = true # security groups allow access only from load balancer
  }

  # # moved to module declaration
  # depends_on = [
  #   module.example_alb,
  #   module.example_alb_tg_listener
  # ]
  tags = {
    Name = "example_ecs_service"
  }
}



# Create role for autoscaling target
resource "aws_iam_role" "example_role_autoscaling_target" {
  name = "example_role_autoscaling_target"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole"
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "application-autoscaling.amazonaws.com"
        },
      }
    ]
  })

  tags = {
    Name = "example_role_autoscaling_target"
  }
}
resource "aws_iam_policy_attachment" "example_role_autoscaling_target_native_policy_attachment" {
  name       = "example_role_autoscaling_target_native_policy_attachment"
  roles      = ["${aws_iam_role.example_role_autoscaling_target.id}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

# Create the autoscaling policies for the ecs cluster service, which create cloudwatch alarms to trigger autoscale acitons
resource "aws_appautoscaling_target" "example_appautoscaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${local.ecs_cluster_name}/${aws_ecs_service.example_ecs_service.name}"
  role_arn           = aws_iam_role.example_role_autoscaling_target.arn
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 0
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

    target_value       = 90.0 # %
    scale_in_cooldown  = 60   # sec
    scale_out_cooldown = 60   # sec
  }

  depends_on = [aws_appautoscaling_target.example_appautoscaling_target]
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

    target_value       = 90.0 # %
    scale_in_cooldown  = 60   # sec
    scale_out_cooldown = 60   # sec
  }

  depends_on = [aws_appautoscaling_target.example_appautoscaling_target]
}
