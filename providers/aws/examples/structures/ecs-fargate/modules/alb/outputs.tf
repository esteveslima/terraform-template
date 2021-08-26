output "alb_arn" {
  description = "alb arn for references"
  value       = aws_lb.example_lb.arn
}

output "alb_dns" {
  description = "alb dns for references"
  value       = aws_lb.example_lb.dns_name
}

output "alb_security_group_tasks_instances_id" {
  description = "alb security group to restrict access for only alb"
  value       = aws_security_group.example_security_group_lb_tasks_instances.id
}
