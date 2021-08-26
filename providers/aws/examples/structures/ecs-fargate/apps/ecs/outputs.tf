# output "lb_dns" {
#   description = "load balancer public lb_dns"
#   value       = aws_lb.example_lb.dns_name
# }
output "lb_dns" {
  description = "load balancer public lb_dns"
  value       = module.example_alb.alb_dns
}

output "ecr_uri" {
  description = "ecr uri"
  value       = module.example_ecr.ecr_repository_url
}
