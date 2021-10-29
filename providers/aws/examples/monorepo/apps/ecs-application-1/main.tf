# Implementing application with ecs fargate infrastructure

locals {
  region = var.region

  task_port                 = var.task_port
  task_env_vars             = var.task_env_vars
  inline_policy             = var.inline_policy_json_file == null ? null : file("${path.cwd}/${var.inline_policy_json_file}")
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  autoscaling_min_tasks     = var.autoscaling_min_tasks
  autoscaling_max_tasks     = var.autoscaling_max_tasks
  autoscaling_target_cpu    = var.autoscaling_target_cpu    // %
  autoscaling_target_memory = var.autoscaling_target_memory // %
}

###############################   Data sources   ###############################

module "data_network_project" {
  source = "../../modules/fetch-s3-state"

  name        = "network-basic"
  environment = local.environment
}

module "data_alb_project" {
  source = "../../modules/fetch-s3-state"

  name        = "alb-general"
  environment = local.environment
}

module "data_ecs_cluster_project" {
  source = "../../modules/fetch-s3-state"

  name        = "ecs-cluster-general"
  environment = local.environment
}



###############################   Application   ###############################


##### ECR

module "ecr" {
  source = "../../modules/ecr"

  name        = local.project
  environment = local.environment
}


##### ALB listener rule forwards to application

module "alb_listener_rule_tg" {
  source = "../../modules/alb-listener-rule-tg"

  name         = local.project
  environment  = local.environment
  vpc_id       = module.data_network_project.remote_state.outputs.vpc.id
  listener_arn = module.data_alb_project.remote_state.outputs.alb.alb_listener.arn

  path         = "/${local.project}*"
  inbound_port = local.task_port
  # methods      = []
}


module "ecs_service" {
  source = "../../modules/ecs-service"

  name        = local.project
  environment = local.environment
  region      = local.region
  subnets_ids = [
    module.data_network_project.remote_state.outputs.public_subnets[0].id,
    module.data_network_project.remote_state.outputs.public_subnets[1].id
  ]
  ecr_url           = module.ecr.ecr.repository_url
  tg_arn            = module.alb_listener_rule_tg.tg.arn
  ecs_cluster_name  = module.data_ecs_cluster_project.remote_state.outputs.ecs_cluster.ecs_cluster.name
  ecs_cluster_arn   = module.data_ecs_cluster_project.remote_state.outputs.ecs_cluster.ecs_cluster.arn
  ecs_service_sg_id = module.data_alb_project.remote_state.outputs.alb.sg_applications_alb.id

  task_port = local.task_port
  # task_secret_vars          = // reference to created secrets ARNs
  task_env_vars             = local.task_env_vars
  task_cpu                  = local.task_cpu
  task_memory               = local.task_memory
  autoscaling_min_tasks     = local.autoscaling_min_tasks
  autoscaling_max_tasks     = local.autoscaling_max_tasks
  autoscaling_target_cpu    = local.autoscaling_target_cpu    // %
  autoscaling_target_memory = local.autoscaling_target_memory // %
  inline_policy             = local.inline_policy
}
