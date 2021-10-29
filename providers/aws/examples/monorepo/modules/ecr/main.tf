# Implementing ecr


locals {
  name        = var.name
  environment = var.environment
}


###############################   Data sources   ###############################






###############################   Application   ###############################



##### Create the docker images repository(ECR)

resource "aws_ecr_repository" "ecr_repository" {
  name                 = "${local.name}-${local.environment}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.name}-${local.environment}-ecr"
  }
}
