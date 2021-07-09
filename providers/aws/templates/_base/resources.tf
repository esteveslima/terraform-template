resource "aws_<resource>" "resource_name" {
  # ...

  tags = {
    Name = var.var_name # Assigning created variable to a resource definition
  }
}
