# Implementing ecs cluster for certain group of applications

locals {

}



###############################   Data sources   ###############################






###############################   Application   ###############################



##### Setup General Purpose Fargate ECS Cluster
# Could be created for a specific application group if needed

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  name        = local.project
  environment = local.environment
}
