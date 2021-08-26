# Implementing network

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

####################################################################################################


locals {

}


####################################################################################################

# Data sources

data "aws_availability_zones" "example_data_source_azs" {
  state = "available"
}



####################################################################################################



# Setup base network
# Create isolated network in the cloud(vpc)
resource "aws_vpc" "example_vpc" {
  cidr_block = var.cidr_vpc

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
# Create public subnetworks inside the vpc in multiple AZs
resource "aws_subnet" "example_subnet_public_1" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = var.cidr_subnet_1
  availability_zone = data.aws_availability_zones.example_data_source_azs.names[0]

  tags = {
    Name = "example_subnet_public_1"
  }
}
resource "aws_subnet" "example_subnet_public_2" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = var.cidr_subnet_2
  availability_zone = data.aws_availability_zones.example_data_source_azs.names[1]

  tags = {
    Name = "example_subnet_public_2"
  }
}

# Create the route table for the public subnets(targeting internet gateway)
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

# Associate the route table to the public subnets
resource "aws_route_table_association" "example_route_table_association_public_subnet_1" {
  subnet_id      = aws_subnet.example_subnet_public_1.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}
resource "aws_route_table_association" "example_route_table_association_public_subnet_2" {
  subnet_id      = aws_subnet.example_subnet_public_2.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}



####################################################################################################
