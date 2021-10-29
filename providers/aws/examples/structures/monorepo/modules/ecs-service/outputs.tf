output "ecs_service" {
  description = "resource's properties object"
  value       = aws_ecs_service.ecs_service
}

output "task_definition" {
  description = "resource's properties object"
  value       = aws_ecs_task_definition.ecs_task_definition
}

