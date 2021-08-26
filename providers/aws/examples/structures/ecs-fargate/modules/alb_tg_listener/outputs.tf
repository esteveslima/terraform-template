output "tg_arn" {
  description = "target group arn for references"
  value       = aws_lb_target_group.example_target_group.arn
}
