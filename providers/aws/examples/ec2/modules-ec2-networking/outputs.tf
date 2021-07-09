# Same outputs from modules

output "ip_instance_1" {
  description = "instance ip"
  value       = module.basic_instance_ec2_1.instance_ip
}

output "ip_instance_2" {
  description = "instance ip"
  value       = module.basic_instance_ec2_2.instance_ip
}
