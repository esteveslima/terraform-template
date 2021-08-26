# Implementing ecs cluster with fargate
# Could be created separetly to be reused by multiple services, instead of being used as a module

locals {

}


####################################################################################################



# Data sources



#



####################################################################################################

# Create ecs cluster
resource "aws_ecs_cluster" "example_ecs_cluster" {
  name               = "example_ecs_cluster"
  capacity_providers = ["FARGATE"]

  tags = {
    Name = "example_ecs_cluster"
  }
}
