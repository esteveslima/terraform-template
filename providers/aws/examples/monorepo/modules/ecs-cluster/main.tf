# Implementing ecs cluster with fargate

# Could be created separetly to be reused by multiple services



locals {
  name        = var.name
  environment = var.environment
}


###############################   Data sources   ###############################






###############################   Application   ###############################

# Create ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name               = "${local.name}-${local.environment}-ecs-cluster"
  capacity_providers = ["FARGATE"]

  tags = {
    Name = "${local.name}-${local.environment}-ecs-cluster"
  }
}
