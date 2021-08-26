output "ecs_cluster_id" {
  description = "id of the created ecs cluster"
  value       = aws_ecs_cluster.example_ecs_cluster.id
}


output "ecs_cluster_name" {
  description = "name of the created ecs cluster"
  value       = aws_ecs_cluster.example_ecs_cluster.name
}
