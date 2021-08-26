# Implementing ecs codebuild as module for codepipeline(TODO: objects may be parametrized by environment/workspace)


locals {
  bucket_pipeline_name = var.bucket_pipeline.bucket
  bucket_pipeline_arn  = var.bucket_pipeline.arn

  ecs_container_name  = var.ecs_container_name
  ecr_repository_name = var.ecr_repository_name

  git_repository = var.git_repository
}


####################################################################################################



# Data sources



data "aws_caller_identity" "example_data_source_account" {}

data "aws_region" "example_data_source_region" {}



####################################################################################################



# Setup code build



resource "aws_iam_role" "example_role_code_build" {
  name = "example_role_code_build"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codebuild.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "example_role_policy_code_build" {
  role = aws_iam_role.example_role_code_build.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Resource" : "*",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        "Resource" : [
          "${local.bucket_pipeline_arn}",
          "${local.bucket_pipeline_arn}/*"
        ]
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
      },
      {
        "Resource" : "*"
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
      }
    ]
  })

}

# resource "aws_codebuild_source_credential" "example" {
#   auth_type   = "PERSONAL_ACCESS_TOKEN"
#   server_type = "GITHUB"
#   token       = "example"
# }

resource "aws_codebuild_project" "example_codebuild_project" {
  name        = "example_codebuild_project"
  description = "example_codebuild_project"

  build_timeout          = 5
  concurrent_build_limit = 1
  service_role           = aws_iam_role.example_role_code_build.arn


  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3" # s3 is the recommended for small builds
    location = local.bucket_pipeline_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    # Variables used in buildspec.yml
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.example_data_source_account.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.example_data_source_region.name
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = local.ecs_container_name
    }
    environment_variable {
      name  = "IMAGE_REPOSITORY"
      value = local.ecr_repository_name
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "example_codebuild_project_log_group"
      stream_name = "example_codebuild_project_log_stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${local.bucket_pipeline_name}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${local.git_repository}.git"
    git_clone_depth = 1
    # buildspec       =  # usually buildspec.yml is specified in the repository
  }

  # # Only for specific scenarios
  # vpc_config {
  #   vpc_id = aws_vpc.example.id

  #   subnets = [
  #     aws_subnet.example1.id,
  #     aws_subnet.example2.id,
  #   ]

  #   security_group_ids = [
  #     aws_security_group.example1.id,
  #     aws_security_group.example2.id,
  #   ]
  # }

  # source_version = "master"

  tags = {
    Name = "example_codebuild_project"
  }
}
