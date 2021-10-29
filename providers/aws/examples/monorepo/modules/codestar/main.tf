# Implementing ecs codestar(source code) as module for codepipeline(objects may be parametrized by environment/workspace)

# It could be created in a separated project and exported as output to other projects, making use of a single connection configuration for all repositories in the organization

locals {
  name        = var.name
  environment = var.environment
}



###############################   Data sources   ###############################






###############################   Application   ###############################




# There is a required manual step to complete the CodeStar connection between AWS and provider(github) on the pipeline settings console
resource "aws_codestarconnections_connection" "codestar_connection" {
  name          = "${local.name}-${local.environment}-codestar"
  provider_type = "GitHub"

  tags = {
    Name = "${local.name}-${local.environment}-codestar"
  }
}
