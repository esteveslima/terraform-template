output "vpc" {
  description = "resource's properties object"
  value       = aws_vpc.vpc
}

output "public_subnets" {
  description = "resources' properties object"
  value = [
    aws_subnet.subnet_public_1,
    aws_subnet.subnet_public_2
  ]
}

output "private_subnets" {
  description = "resources' properties object"
  value = [
    aws_subnet.subnet_private_1,
    aws_subnet.subnet_private_2
  ]
}
