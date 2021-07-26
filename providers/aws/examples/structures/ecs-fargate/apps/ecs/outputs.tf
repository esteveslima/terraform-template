output "lb_dns" {
  description = "load balancer public lb_dns"
  value       = aws_lb.example_lb.dns_name
  sensitive   = false
}

output "ecr_uri" {
  description = "ecr uri"
  value       = aws_ecr_repository.example_ecr_repository.repository_url
  sensitive   = false
}
