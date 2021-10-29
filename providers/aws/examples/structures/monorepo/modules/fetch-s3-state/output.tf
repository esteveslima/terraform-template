output "remote_state" {
  description = "Data source remote state result"
  value       = data.terraform_remote_state.remote_state
}
