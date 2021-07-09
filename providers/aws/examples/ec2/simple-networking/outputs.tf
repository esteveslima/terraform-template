output "instance_ip" {
  description = "instance ip"
  value       = aws_instance.example_ec2.public_ip
  sensitive   = false
}
