# Code source for pipeline(using codestar connection)

locals {

}



###############################   Data sources   ###############################






###############################   Application   ###############################



##### Setup pipeline code source connection(Github)

module "codesource" {
  source = "../../modules/codestar"

  name        = local.project
  environment = local.environment
}
