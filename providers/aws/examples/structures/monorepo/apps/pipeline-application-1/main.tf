# Implementing ecs pipeline(objects may be parametrized by environment/workspace)

locals {
  region = var.region

  source_repository          = var.source_repository
  source_repository_branch   = var.source_repository_branch
  inline_policy_codebuild    = var.inline_policy_codebuild_json_file == null ? null : file("${path.cwd}/${var.inline_policy_codebuild_json_file}")
  inline_policy_codepipeline = var.inline_policy_codepipeline_json_file == null ? null : file("${path.cwd}/${var.inline_policy_codepipeline_json_file}")
}

###############################   Data sources   ###############################

module "data_network_project" {
  source = "../../modules/fetch-s3-state"

  name        = "network-basic"
  environment = local.environment
}

module "data_ecs_cluster_project" {
  source = "../../modules/fetch-s3-state"

  name        = "ecs-cluster-general"
  environment = local.environment
}
module "data_ecs_service_project" {
  source = "../../modules/fetch-s3-state"

  name        = "ecs-application-1"
  environment = local.environment
}

module "data_codesource_project" {
  source = "../../modules/fetch-s3-state"

  name        = "codesource"
  environment = local.environment
}
module "data_pipeline_resources_project" {
  source = "../../modules/fetch-s3-state"

  name        = "pipeline-resources"
  environment = local.environment
}

data "aws_caller_identity" "aws_identity" {}

###############################   Application   ###############################



##### Setup code build

module "codebuild" {
  source = "../../modules/codebuild"

  name        = local.project
  environment = local.environment
  bucket_arn  = module.data_pipeline_resources_project.remote_state.outputs.codepipeline_s3_bucket.arn
  bucket_name = module.data_pipeline_resources_project.remote_state.outputs.codepipeline_s3_bucket.id

  source_repository = local.source_repository
  inline_policy     = local.inline_policy_codebuild
  build_env_vars = {
    "AWS_ACCOUNT_ID"   = data.aws_caller_identity.aws_identity.account_id
    "AWS_REGION"       = local.region
    "CONTAINER_NAME"   = jsondecode(module.data_ecs_service_project.remote_state.outputs.ecs_service.task_definition.container_definitions)[0].name
    "IMAGE_REPOSITORY" = module.data_ecs_service_project.remote_state.outputs.ecr.ecr.name
    "IMAGE_TAG"        = "latest"
  }
}


##### Setup code pipeline

module "codepipeline" {
  source = "../../modules/codepipeline"

  name                   = local.project
  environment            = local.environment
  bucket_arn             = module.data_pipeline_resources_project.remote_state.outputs.codepipeline_s3_bucket.arn
  bucket_name            = module.data_pipeline_resources_project.remote_state.outputs.codepipeline_s3_bucket.id
  codesource_arn         = module.data_codesource_project.remote_state.outputs.codesource.codestar.id
  codebuild_project_name = module.codebuild.codebuild.name
  ecs_cluster_name       = module.data_ecs_cluster_project.remote_state.outputs.ecs_cluster.ecs_cluster.name
  ecs_service_name       = module.data_ecs_service_project.remote_state.outputs.ecs_service.ecs_service.name

  source_repository        = local.source_repository
  source_repository_branch = local.source_repository_branch
  inline_policy            = local.inline_policy_codepipeline
}
