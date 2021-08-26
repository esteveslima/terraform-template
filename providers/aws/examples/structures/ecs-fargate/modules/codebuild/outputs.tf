output "codebuild_name" {
  description = "codebuild project name"
  value       = aws_codebuild_project.example_codebuild_project.name
}
