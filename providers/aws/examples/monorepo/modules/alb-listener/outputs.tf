output "alb" {
  description = "resource's properties object"
  value       = aws_lb.alb
}

output "sg_applications_alb" {
  description = "resource's properties object"
  value       = module.sg_applications_alb.sg
}

output "alb_listener" {
  description = "resource's properties object"
  value       = aws_lb_listener.alb_listener
}
