# Implementing ecr


locals {

}


####################################################################################################



# Data sources



#



####################################################################################################

# Create the docker images repository(ECR)
resource "aws_ecr_repository" "example_ecr_repository" {
  name                 = "example_ecr_repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "example_ecr_repository"
  }
}
