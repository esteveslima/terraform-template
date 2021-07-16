output "instance_ip" {
  description = "some instance ip"
  value       = aws_instance.example_ec2_public[0].public_ip
  sensitive   = false
}
