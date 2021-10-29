# Implementing fargate ecs service, with single container task definition and autoscaling


locals {
  name              = var.name
  environment       = var.environment
  region            = var.region
  tg_arn            = var.tg_arn
  subnets_ids       = var.subnets_ids
  ecs_service_sg_id = var.ecs_service_sg_id
  ecs_cluster_arn   = var.ecs_cluster_arn
  ecs_cluster_name  = var.ecs_cluster_name
  ecr_url           = var.ecr_url

  task_port                 = var.task_port
  task_command              = var.task_command
  task_env_vars             = var.task_env_vars
  task_secret_vars          = var.task_secret_vars
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  autoscaling_min_tasks     = var.autoscaling_min_tasks
  autoscaling_max_tasks     = var.autoscaling_max_tasks
  autoscaling_target_cpu    = var.autoscaling_target_cpu
  autoscaling_target_memory = var.autoscaling_target_memory
  inline_policy             = var.inline_policy
}


###############################   Data sources   ###############################






###############################   Application   ###############################

##### IAM Role

resource "aws_iam_role" "role_task_definition" { // one per application
  name = "${local.name}-${local.environment}-task-definition-role"

  assume_role_policy = file("${path.module}/iam/task-definition-role.json")

  dynamic "inline_policy" {
    for_each = local.inline_policy != null ? toset([1]) : toset([]) // Conditionally create the inline policy if the policy is provided
    content {
      name   = "${local.name}-${local.environment}-custom-inline-policy"
      policy = local.inline_policy
    }
  }

  tags = {
    Name = "${local.name}-${local.environment}-task-definition-role"
  }
}

resource "aws_iam_policy" "role_policy_task_definition" {
  name        = "task-definition-ecs-policy-${local.environment}"
  description = "task-definition-ecs-policy-${local.environment}"

  policy = file("${path.module}/iam/task-definition-policy.json")

  tags = {
    Name = "task-definition-ecs-policy-${local.environment}"
  }
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.role_task_definition.name
  policy_arn = aws_iam_policy.role_policy_task_definition.arn
}



##### Logs resources

resource "aws_cloudwatch_log_group" "task_log_group" {
  name = "${local.name}-${local.environment}-log-group"
}
resource "aws_cloudwatch_log_stream" "task_log_stream" {
  name           = "${local.name}-${local.environment}-log-stream"
  log_group_name = aws_cloudwatch_log_group.task_log_group.name
}



##### Task definition 

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${local.name}-${local.environment}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.task_cpu
  memory                   = local.task_memory
  execution_role_arn       = aws_iam_role.role_task_definition.arn
  task_role_arn            = aws_iam_role.role_task_definition.arn

  container_definitions = jsonencode([
    {
      "name" : "${local.name}-${local.environment}-ecs-container",
      "image" : local.ecr_url,

      # "command" : "",
      "portMappings" : [{ "containerPort" : local.task_port, "hostPort" : local.task_port }]
      "privileged" : false,
      "essential" : true,
      "environment" : [
        for env_var_key, env_var_value in local.task_env_vars :
        {
          name : env_var_key,
          value : env_var_value
        }
      ],
      "secrets" : [
        for secret_var_key, secret_var_value in local.task_secret_vars :
        {
          name : secret_var_key,
          valueFrom : secret_var_value // secret arn
        }
      ]

      "cpu" : local.task_cpu,
      "memory" : local.task_memory,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : local.region,
          "awslogs-group" : aws_cloudwatch_log_group.task_log_group.name
          "awslogs-stream-prefix" : aws_cloudwatch_log_stream.task_log_stream.name
        }
      }
      # "mountPoints": "",
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
    Name = "${local.name}-${local.environment}-task-definition"
  }
}



##### ECS Service

# Create a service in the cluster for task definition
resource "aws_ecs_service" "ecs_service" {
  name            = "${local.name}-${local.environment}-ecs-service"
  cluster         = local.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"                    # could also be used capacity provider config(?)
  desired_count   = 1                            # initial count, further scaled by app autoscaling
  lifecycle { ignore_changes = [desired_count] } # ignore further lifecycle changes and preserve autoscaling desired count


  load_balancer {
    target_group_arn = local.tg_arn
    container_name   = jsondecode(aws_ecs_task_definition.ecs_task_definition.container_definitions)[0].name
    container_port   = local.task_port
  }

  network_configuration {
    subnets          = local.subnets_ids
    security_groups  = [local.ecs_service_sg_id]
    assign_public_ip = true # security groups allow access only from load balancer
  }

  tags = {
    Name = "${local.name}-${local.environment}-ecs-service"
  }
}



##### Service autoscaling

# Create role for autoscaling target
resource "aws_iam_role" "role_autoscaling_target" {
  name               = "${local.name}-${local.environment}-autoscaling-role"
  assume_role_policy = file("${path.module}/iam/autoscaling-role.json")

  tags = {
    Name = "${local.name}-${local.environment}-autoscaling-role"
  }
}
resource "aws_iam_policy_attachment" "role_autoscaling_target_native_policy_attachment" {
  name       = "role_autoscaling_target_native_policy_attachment-${terraform.workspace}"
  roles      = ["${aws_iam_role.role_autoscaling_target.id}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole" // Policy provided by AWS 
}

# Create the autoscaling policies for the ecs cluster service, which create cloudwatch alarms to trigger autoscale acitons
resource "aws_appautoscaling_target" "appautoscaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${local.ecs_cluster_name}/${aws_ecs_service.ecs_service.name}"
  role_arn           = aws_iam_role.role_autoscaling_target.arn
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = local.autoscaling_min_tasks
  max_capacity       = local.autoscaling_max_tasks
}
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${local.name}-${local.environment}-autoscaling-memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = local.autoscaling_target_memory # %
    scale_in_cooldown  = 60                              # sec
    scale_out_cooldown = 60                              # sec
  }

  depends_on = [aws_appautoscaling_target.appautoscaling_target]
}
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${local.name}-${local.environment}-autoscaling-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = local.autoscaling_target_cpu # %
    scale_in_cooldown  = 60                           # sec
    scale_out_cooldown = 60                           # sec
  }

  depends_on = [aws_appautoscaling_target.appautoscaling_target]
}

# https://dev.to/kieranjen/ecs-fargate-service-auto-scaling-with-terraform-2ld
# https://towardsaws.com/aws-ecs-service-autoscaling-terraform-included-d4b46997742b
