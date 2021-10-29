# Implementing ecs codebuild as module for codepipeline(TODO: objects may be parametrized by environment/workspace)


locals {
  name        = var.name
  environment = var.environment
  bucket_name = var.bucket_name
  bucket_arn  = var.bucket_arn

  source_repository = var.source_repository
  build_env_vars    = var.build_env_vars
  inline_policy     = var.inline_policy
}


###############################   Data sources   ###############################





###############################   Application   ###############################

##### IAM Role

resource "aws_iam_role" "role_code_build" {
  name = "${local.name}-${local.environment}-codebuild-role"

  assume_role_policy = file("${path.module}/iam/codebuild-role.json")

  dynamic "inline_policy" {
    for_each = local.inline_policy != null ? toset([1]) : toset([]) // Conditionally create the inline policy if the policy is provided
    content {
      name   = "${local.name}-${local.environment}-custom-inline-policy"
      policy = local.inline_policy
    }
  }

  tags = {
    Name = "${local.name}-${local.environment}-codebuild-role"
  }
}

resource "aws_iam_policy" "role_policy_code_build" {
  name        = "codebuild-ecs-policy-${local.environment}"
  description = "codebuild-ecs-policy-${local.environment}"

  policy = templatefile("${path.module}/iam/codebuild-ecs-policy.json", {
    bucket_build_arn = local.bucket_arn
  })

  tags = {
    Name = "codebuild-ecs-policy-${local.environment}"
  }
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.role_code_build.name
  policy_arn = aws_iam_policy.role_policy_code_build.arn
}



# resource "aws_codebuild_source_credential" "codebuild_source_credential" {
#   auth_type   = "PERSONAL_ACCESS_TOKEN"
#   server_type = "GITHUB"
#   token       = "example"
# }

###### Codebuild Project

resource "aws_codebuild_project" "codebuild_project" {
  name        = "${local.name}-${local.environment}-codebuild-project"
  description = "${local.name}-${local.environment}-codebuild-project"

  build_timeout          = 5
  concurrent_build_limit = 1
  service_role           = aws_iam_role.role_code_build.arn


  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3" # s3 is the recommended for small builds
    location = local.bucket_name
  }

  environment { # offer preset options and also allow manually set one parameter?
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    # Variables used in buildspec.yml
    dynamic "environment_variable" {
      for_each = local.build_env_vars
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${local.source_repository}.git"
    git_clone_depth = 1
    # buildspec       =  # usually buildspec.yml is specified in the source repository
  }

  # logs_config {
  #   # cloudwatch_logs {
  #   #   group_name  = "${local.name}-${local.environment}-codebuild-project-log-group"  // requires create the resource
  #   #   stream_name = "${local.name}-${local.environment}-codebuild-project-log-stream" // requires create the resource
  #   # }
  #   # s3_logs {
  #   #   status   = "ENABLED"
  #   #   location = "${local.bucket_name}/${local.name}/logs"
  #   # }
  # }

  # vpc_config {
  #   vpc_id = aws_vpc.example.id
  #   subnets = []
  #   security_group_ids = []
  # }

  # source_version = "master"

  tags = {
    Name = "${local.name}-${local.environment}-codebuild-project"
  }
}
