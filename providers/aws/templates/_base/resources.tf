# Constants assignment
locals {
  some_local = {
    Name = var.var_name # Assigning with created variable
  }
}

resource "aws_<resource>" "resource_name" {
  # ...

  tags = local.some_local
}
