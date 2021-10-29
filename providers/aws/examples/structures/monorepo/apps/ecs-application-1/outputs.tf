output "alb_listener_rule_tg" {
  description = "resource's properties object"
  value       = module.alb_listener_rule_tg
}

output "ecr" {
  description = "resource's properties object"
  value       = module.ecr
}

output "ecs_service" {
  description = "resource's properties object"
  value       = module.ecs_service
}
