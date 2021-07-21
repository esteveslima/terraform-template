# Implementing a webserver cenario with public and private servers, in addition to a bastion server for monitoring

# TODO: split in modules

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

locals {

}



####################################################################################################



# Setup base network
# Create isolated network in the cloud(vpc)
resource "aws_vpc" "example_vpc" {
  cidr_block = "100.100.0.0/16" # 2^(32-16)-2 = 65534 available addresses(100.100.0.1 ~ 100.100.255.254) for the vpc

  tags = {
    Name = "example_vpc"
  }
}
# Create the internet entry point for the vpc
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
    Name = "example_igw"
  }
}



####################################################################################################



# Setup public az subnet in the vpc(with inbound and outbound traffic)
# Create a public subnetwork inside the vpc
resource "aws_subnet" "example_subnet_public" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "100.100.0.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.0.0 ~ 100.100.0.13) 
  map_public_ip_on_launch = true             # assign a public ip to instances in this subnet

  tags = {
    Name = "example_subnet_public"
  }
}
# Create the route table for the public subnet(targeting internet gateway)
resource "aws_route_table" "example_route_table_public_subnet" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "example_route_table_public_subnet"
  }
}
# Associate the route table to the public subnet
resource "aws_route_table_association" "example_route_table_association_public_subnet" {
  subnet_id      = aws_subnet.example_subnet_public.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}



# Setup private az subnet in vpc(with only outbound internet access throught public nat)
# Create a private subnetwork inside the vpc
resource "aws_subnet" "example_subnet_private" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "100.100.1.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.1.0 ~ 100.100.1.13) 
  # TODO: understand the cidr addresses better, some attempts result on error before
  tags = {
    Name = "example_subnet_private"
  }
}
# Create the elastic ip for the nat(providing public ip)
resource "aws_eip" "example_eip_nat" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "example_eip_nat"
  }
}
# Create the nat for the private subnet(must be created on a public subnet)
resource "aws_nat_gateway" "example_nat_public" {
  connectivity_type = "public"
  allocation_id     = aws_eip.example_eip_nat.id
  subnet_id         = aws_subnet.example_subnet_public.id

  depends_on = [aws_internet_gateway.example_igw]
  tags = {
    Name = "example_nat_public"
  }
}
# Create the route table for the private subnet(targeting nat gateway)
resource "aws_route_table" "example_route_table_private_subnet" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example_nat_public.id
  }

  tags = {
    Name = "example_route_table_private_subnet"
  }
}
# Associate the route table to the private subnet
resource "aws_route_table_association" "example_route_table_association_private_subnet" {
  subnet_id      = aws_subnet.example_subnet_private.id
  route_table_id = aws_route_table.example_route_table_private_subnet.id
}



####################################################################################################



# Setup bastion host(instance security must be reinforced)
# Create the security group for the bastion
resource "aws_security_group" "example_security_group_bastion" {
  name        = "example_security_group_bastion"
  description = "Allow only outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    description      = "allow icmp(ping) from secure host/user"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"] # Set access only for trusted known users, do not allow all ip adresses(0.0.0.0/0) like this example
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "allow ssh from secure host/user"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Set access only for trusted known users, do not allow all ip adresses(0.0.0.0/0) like this example
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_bastion"
  }
}
# Create bastion key pair
resource "aws_key_pair" "example_key_pair_bastion" {
  key_name   = "example_key_pair_bastion"
  public_key = file("${path.module}/keypairs/bastion_id_rsa.pub")
}
# Create bastion instance
resource "aws_instance" "example_ec2_bastion" {
  ami           = var.instance_ami
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.example_subnet_public.id
  vpc_security_group_ids = [aws_security_group.example_security_group_bastion.id]
  key_name               = aws_key_pair.example_key_pair_bastion.key_name

  tags = {
    Name = "ec2-example-bastion"
  }
}
# Create the elastic ip for the bastion
resource "aws_eip" "example_eip_bastion" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "example_eip_bastion"
  }
}
# Assign elastic ip to bastion instance
resource "aws_eip_association" "example_eip_bastion_association" {
  instance_id   = aws_instance.example_ec2_bastion.id
  allocation_id = aws_eip.example_eip_bastion.id
}


####################################################################################################



# Setup EC2 Instances

# Setup security groups for instances
# Create the basic security group for the instances
resource "aws_security_group" "example_security_group_base_instances" {
  name        = "example_security_group_base_instances"
  description = "Allow only outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    description     = "allow icmp(ping) from bastion"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.example_security_group_bastion.id] # from bastion security group access only        
  }
  ingress {
    description     = "allow ssh from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.example_security_group_bastion.id] # from bastion security group access only    
  }

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_base_instances"
  }
}
# Create the security group for the public instances(webserver)
resource "aws_security_group" "example_security_group_public_instances" {
  name        = "example_security_group_public_instances"
  description = "Allow all inbound/outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    description      = "allow http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "allow https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "allow arbitrary port"
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_public_instances"
  }
}
# Create the security group for the private instances(back services)
resource "aws_security_group" "example_security_group_private_instances" {
  name        = "example_security_group_private_instances"
  description = "Allow all inbound/outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    description      = "allow arbitrary private ports for services"
    from_port        = 8000
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_private_instances"
  }
}

# Create apps key pair(using the same key pair for all instances for the sake of the example)
resource "aws_key_pair" "example_key_pair_apps" {
  key_name   = "example_key_pair_apps"
  public_key = file("${path.module}/keypairs/apps_id_rsa.pub")
}



# Create ec2 instances with the created network infrastructure
# webservers(backend/frontend)
resource "aws_instance" "example_ec2_public" {
  ami           = var.instance_ami
  instance_type = "t2.micro"
  count         = 2

  subnet_id = aws_subnet.example_subnet_public.id
  vpc_security_group_ids = [
    aws_security_group.example_security_group_base_instances.id,
    aws_security_group.example_security_group_public_instances.id
  ]
  key_name = aws_key_pair.example_key_pair_apps.key_name

  tags = {
    Name = "ec2-example-public_${count.index}"
  }
}
# private resources(databases/workers)
resource "aws_instance" "example_ec2_private" {
  ami           = var.instance_ami
  instance_type = "t2.micro"
  count         = 2

  subnet_id = aws_subnet.example_subnet_private.id
  vpc_security_group_ids = [
    aws_security_group.example_security_group_base_instances.id,
    aws_security_group.example_security_group_private_instances.id
  ]
  key_name = aws_key_pair.example_key_pair_apps.key_name

  tags = {
    Name = "ec2-example-private_${count.index}"
  }
}
