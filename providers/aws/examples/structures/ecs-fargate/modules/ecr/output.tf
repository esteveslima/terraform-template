output "ecr_repository_url" {
  description = "url from created ecr"
  value       = aws_ecr_repository.example_ecr_repository.repository_url
}
