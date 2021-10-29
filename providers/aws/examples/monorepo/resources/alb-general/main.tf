# Implementing alb for certaing group of applications

locals {
  inbound_ports = var.inbound_ports
}



###############################   Data sources   ###############################



module "data_network_project" {
  source = "../../modules/fetch-s3-state"

  name        = "network-basic"
  environment = local.environment
}



###############################   Application   ###############################



##### Setup General Purpose ALB
# Could be created others per individual application or application group if needed

module "alb_general" {
  source = "../../modules/alb-listener"

  name        = local.project
  environment = local.environment
  vpc_id      = module.data_network_project.remote_state.outputs.vpc.id
  subnets_ids = [
    module.data_network_project.remote_state.outputs.public_subnets[0].id,
    module.data_network_project.remote_state.outputs.public_subnets[1].id
  ]
  inbound_ports = local.inbound_ports
}

##### TODO: setup route53? on module or application?
##### TODO: setup service discovery or route53 on application?
