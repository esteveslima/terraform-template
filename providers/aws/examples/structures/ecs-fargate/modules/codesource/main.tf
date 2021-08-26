# Implementing ecs codestart(source code) as module for codepipeline(objects may be parametrized by environment/workspace)


locals {

}


####################################################################################################



# There is a required manual step to complete the CodeStar connection between AWS and provider(github) on the pipeline settings console
resource "aws_codestarconnections_connection" "example_codestar_connection" {
  name          = "example_codestar_connection"
  provider_type = "GitHub"

  tags = {
    Name = "example_codestar_connection"
  }
}
