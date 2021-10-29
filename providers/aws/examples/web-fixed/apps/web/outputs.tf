output "bastion_elastic_ip" {
  description = "bastion elastic public ip to be used for ssh access"
  value       = aws_eip.example_eip_bastion.public_ip
  sensitive   = false
}

output "public_instance_public_ip_0" {
  value     = aws_instance.example_ec2_public[0].public_ip
  sensitive = false
}

output "public_instance_public_ip_1" {
  value     = aws_instance.example_ec2_public[1].public_ip
  sensitive = false
}

###

output "public_instance_private_ip_0" {
  value     = aws_instance.example_ec2_public[0].private_ip
  sensitive = false
}

output "public_instance_private_ip_1" {
  value     = aws_instance.example_ec2_public[1].private_ip
  sensitive = false
}

output "private_instance_private_ip_0" {
  value     = aws_instance.example_ec2_private[0].private_ip
  sensitive = false
}

output "private_instance_private_ip_1" {
  value     = aws_instance.example_ec2_private[1].private_ip
  sensitive = false
}
