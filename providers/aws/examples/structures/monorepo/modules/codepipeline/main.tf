# Implementing codepipeline as module

locals {
  name                   = var.name
  environment            = var.environment
  codesource_arn         = var.codesource_arn
  bucket_name            = var.bucket_name
  bucket_arn             = var.bucket_arn
  codebuild_project_name = var.codebuild_project_name
  ecs_cluster_name       = var.ecs_cluster_name
  ecs_service_name       = var.ecs_service_name

  source_repository        = var.source_repository
  source_repository_branch = var.source_repository_branch
  inline_policy            = var.inline_policy
}



###############################   Data sources   ###############################






###############################   Application   ###############################

##### IAM Role

resource "aws_iam_role" "role_code_pipeline" {
  name = "${local.name}-${local.environment}-codepipeline-role"

  assume_role_policy = file("${path.module}/iam/codepipeline-role.json")

  dynamic "inline_policy" {
    for_each = local.inline_policy != null ? toset([1]) : toset([]) // Conditionally create the inline policy if the policy is provided
    content {
      name   = "${local.name}-${local.environment}-custom-inline-policy"
      policy = local.inline_policy
    }
  }

  tags = {
    Name = "${local.name}-${local.environment}-codepipeline-role"
  }
}

resource "aws_iam_policy" "role_policy_code_pipeline" {
  name        = "codepipeline-ecs-policy-${local.environment}"
  description = "codepipeline-ecs-policy-${local.environment}"

  policy = templatefile("${path.module}/iam/codepipeline-ecs-policy.json", {
    bucket_pipeline_arn = local.bucket_arn
    codestar_arn        = local.codesource_arn
  })

  tags = {
    Name = "codepipeline-ecs-policy-${local.environment}"
  }
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.role_code_pipeline.name
  policy_arn = aws_iam_policy.role_policy_code_pipeline.arn
}



##### Code pipeline

resource "aws_codepipeline" "codepipeline" {
  name     = "${local.name}-${local.environment}-codepipeline"
  role_arn = aws_iam_role.role_code_pipeline.arn

  artifact_store {
    location = local.bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "${local.name}-${local.environment}-source-action"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["${local.name}-${local.environment}-source-output"]

      configuration = {
        ConnectionArn    = local.codesource_arn
        FullRepositoryId = local.source_repository
        BranchName       = local.source_repository_branch
        DetectChanges    = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "${local.name}-${local.environment}-build-action"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["${local.name}-${local.environment}-source-output"]
      output_artifacts = ["${local.name}-${local.environment}-build-output"]

      configuration = {
        ProjectName = local.codebuild_project_name
        # EnvironmentVariables = # env variables defined at codebuild
      }
    }
  }

  dynamic "stage" {
    for_each = (local.ecs_cluster_name != null && local.ecs_service_name != null) ? toset([1]) : toset([]) // Conditionally create the ecs deploy action if the cluster and service were provided
    content {
      name = "Deploy"

      action {
        name            = "${local.name}-${local.environment}-deploy-action"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        version         = "1"
        input_artifacts = ["${local.name}-${local.environment}-build-output"]

        configuration = {
          ClusterName = local.ecs_cluster_name
          ServiceName = local.ecs_service_name
          # FileName  = # imagedefinitions.json is created in buildspec.yml
        }
      }
    }
  }

  tags = {
    Name = "${local.name}-${local.environment}-codepipeline"
  }
}
