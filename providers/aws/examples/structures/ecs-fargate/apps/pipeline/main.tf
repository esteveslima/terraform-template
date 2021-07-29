# Implementing ecs pipeline

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


# Data sources

data "aws_caller_identity" "example_data_source_account" {}

data "aws_region" "example_data_source_region" {}



####################################################################################################



# Setup code source
# There is a required manual step to complete the CodeStar connection between AWS and provider(github) on the console settings

resource "aws_codestarconnections_connection" "example_codestar_connection" {
  name          = "example_codestar_connection"
  provider_type = "GitHub"

  tags = {
    Name = "example_codestar_connection"
  }
}




####################################################################################################


# Setup code build


resource "aws_s3_bucket" "example_bucket_pipeline" {
  bucket = "example-bucket-pipeline"
  acl    = "private"
}


// TODO: fix iam orles with data sources
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
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ],
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "${aws_s3_bucket.example_bucket_pipeline.arn}",
          "${aws_s3_bucket.example_bucket_pipeline.arn}/*"
        ]
      },
      {
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
        "Resource" : "*"
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
    type     = "S3" # recommended for small builds
    location = aws_s3_bucket.example_bucket_pipeline.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.example_data_source_account.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.example_data_source_region.name
    }
    environment_variable {
      name  = "IMAGE_REPOSITORY"
      value = "example_ecr_repository"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "example_ecs_service"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "example_codebuild_project_log_group"
      stream_name = "example_codebuild_project_log_stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.example_bucket_pipeline.id}/build-log"
    }
  }

  # TODO: with data sources
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

  source {
    type            = "GITHUB"
    location        = "https://github.com/esteveslima-solvimm/test-pipeline.git"
    git_clone_depth = 1
    # buildspec       =  # normally buildspec.yml is specified in the repository
  }

  source_version = "master"

  tags = {
    Name = "example_codebuild_project"
  }
}



####################################################################################################


# Setup code deploy


#


####################################################################################################



# Setup code pipeline



# resource "aws_s3_bucket" "example_codepipeline_bucket" {
#   bucket = "example-codepipeline-bucket"
#   acl    = "private"
# }

resource "aws_iam_role" "example_codepipeline_role" {
  name = "test-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codepipeline.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "example_codepipeline_policy" {
  name = "example_codepipeline_policy"
  role = aws_iam_role.example_codepipeline_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.example_bucket_pipeline.arn}",
          "${aws_s3_bucket.example_bucket_pipeline.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codestar-connections:UseConnection"
        ],
        "Resource" : "${aws_codestarconnections_connection.example_codestar_connection.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        "Resource" : "*"
      },
      {
        "Action" : [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetApplication",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "iam:PassRole"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
      },
      {
        "Action" : [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

# data "aws_kms_alias" "s3kmskey" {
#   name = "alias/myKmsKey"
# }



resource "aws_codepipeline" "example_codepipeline" {
  name     = "example_codepipeline"
  role_arn = aws_iam_role.example_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.example_bucket_pipeline.bucket
    type     = "S3"

    # encryption_key {
    #   id   = data.aws_kms_alias.s3kmskey.arn
    #   type = "KMS"
    # }
  }

  stage {
    name = "Source"

    action {
      name             = "example_source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["example_source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example_codestar_connection.arn
        FullRepositoryId = "esteveslima-solvimm/test-pipeline"
        BranchName       = "main"
        DetectChanges    = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "example_build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["example_source_output"]
      output_artifacts = ["example_build_output"]
      version          = "1"

      configuration = {
        ProjectName = "example_codebuild_project"
        # EnvironmentVariables =
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "example_deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["example_build_output"]
      version         = "1"

      configuration = {
        ClusterName = "example_ecs_cluster" # TODO: replace with data source
        ServiceName = "example_ecs_service" # TODO: replace with data source
        # FileName  = # imagedefinitions.json is created with buildspec.yml
      }
    }
  }

  depends_on = [
    aws_iam_role.example_codepipeline_role,
    aws_iam_role_policy.example_codepipeline_policy
  ]
  tags = {
    Name = "example_codepipeline"
  }
}



####################################################################################################



# Setup pipeline webhook trigger
