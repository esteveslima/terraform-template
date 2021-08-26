output "vpc_cidr" {
  description = "print vpc cidr"
  value       = aws_vpc.example_vpc.cidr_block
}



data "aws_subnet_ids" "example_data_source_subnets_ids" {
  vpc_id = aws_vpc.example_vpc.id
  depends_on = [
    aws_subnet.example_subnet_public_1,
    aws_subnet.example_subnet_public_2
  ]
}
output "subnets_ids" {
  description = "print subnets cidr"
  value       = data.aws_subnet_ids.example_data_source_subnets_ids.ids
}
