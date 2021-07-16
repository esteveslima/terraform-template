# Implementing the scenario: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html
# Route table config: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html#nat-gateway-scenarios

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
  region  = "us-east-1"
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



# (TODO: enhance understanding of networking)



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
# Create the security group for the public instances(allow all traffic)
resource "aws_security_group" "example_security_group_public_instances" {
  name        = "example_security_group_public_instances"
  description = "Allow all inbound/outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "allow all"
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
resource "aws_eip" "example_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "example_eip"
  }
}
# Create the nat for the private subnet
resource "aws_nat_gateway" "example_nat_public" {
  connectivity_type = "public"
  allocation_id     = aws_eip.example_eip.id
  subnet_id         = aws_subnet.example_subnet_private.id

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
# Create the security group for the private instances(allow outbound traffic)
resource "aws_security_group" "example_security_group_private_instances" {
  name        = "example_security_group_private_instances"
  description = "Allow only outbound traffic"
  vpc_id      = aws_vpc.example_vpc.id

  egress {
    description      = "allow all"
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



#(TODO: implement load balancer for public subnet instances)
#(TODO: maintenance/ssh entry point for instances public or private)



# Setup EC2 

# # Fetch instance AMI(could'nt make it work properly)
# data "aws_ami" "ami_amz_t2micro" {
#   # most_recent = true
#   # owners      = [""]  

#   # filter {
#   #   name   = ""
#   #   values = [""]
#   # }
# }

resource "aws_instance" "example_ec2_public" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
  count         = 2

  subnet_id              = aws_subnet.example_subnet_public.id
  vpc_security_group_ids = [aws_security_group.example_security_group_public_instances.id]

  tags = {
    Name = "ec2-example-public_${count.index}"
  }
}

resource "aws_instance" "example_ec2_private" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
  count         = 2

  subnet_id              = aws_subnet.example_subnet_private.id
  vpc_security_group_ids = [aws_security_group.example_security_group_private_instances.id]

  tags = {
    Name = "ec2-example-private_${count.index}"
  }
}
