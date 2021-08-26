# Implementing ecs pipeline(objects may be parametrized by environment/workspace)

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
  ecs_cluster_name    = "example_ecs_cluster"
  ecs_service_name    = "example_ecs_service"
  ecs_container_name  = "example_ecs_container"
  ecr_repository_name = "example_ecr_repository"



  # There is a required manual step to complete the CodeStar connection between AWS and provider(github) on the pipeline settings console
  git_repository = var.git_repository
  git_branch     = var.git_branch
}



####################################################################################################



# Data sources


#



####################################################################################################



# Setup common basic resources


resource "aws_s3_bucket" "example_bucket_pipeline" {
  bucket = "example-bucket-pipeline"
  acl    = "private"

  tags = {
    Name = "example_bucket_pipeline"
  }
}



####################################################################################################



# Setup code source



# There is a required manual step to complete the CodeStar connection between AWS and provider(github) on the pipeline settings console
module "example_module_codesource" {
  source = "../../modules/codesource"

}



####################################################################################################



# Setup code build



module "example_module_codebuild" {
  source = "../../modules/codebuild"

  git_repository      = local.git_repository
  bucket_pipeline     = aws_s3_bucket.example_bucket_pipeline
  ecs_container_name  = local.ecs_container_name
  ecr_repository_name = local.ecr_repository_name
}



####################################################################################################



# Setup code deploy



# Not using, setting ECS as deployment provider


####################################################################################################



# Setup code pipeline



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
        "Resource" : [
          "${aws_s3_bucket.example_bucket_pipeline.arn}",
          "${aws_s3_bucket.example_bucket_pipeline.arn}/*"
        ]
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ],
      },
      {
        "Resource" : "${module.example_module_codesource.codestar_arn}"
        "Effect" : "Allow",
        "Action" : [
          "codestar-connections:UseConnection"
        ],
      },
      {
        "Resource" : "*"
        "Effect" : "Allow",
        "Action" : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
      },
      {
        "Resource" : "*",
        "Effect" : "Allow"
        "Action" : [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetApplication",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
      },
      {
        "Resource" : "*",
        "Effect" : "Allow"
        "Action" : [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ],
      },
      {
        "Resource" : "*",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
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
      output_artifacts = ["example_source_output_name"]

      configuration = {
        ConnectionArn    = module.example_module_codesource.codestar_arn
        FullRepositoryId = local.git_repository
        BranchName       = local.git_branch
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
      input_artifacts  = ["example_source_output_name"]
      output_artifacts = ["example_build_output_name"]
      version          = "1"

      configuration = {
        ProjectName = module.example_module_codebuild.codebuild_name
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
      input_artifacts = ["example_build_output_name"]
      version         = "1"

      configuration = {
        ClusterName = local.ecs_cluster_name
        ServiceName = local.ecs_service_name
        # FileName  = # imagedefinitions.json is created in buildspec.yml
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
