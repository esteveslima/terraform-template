# Implementing project's basic network to run examples

locals {
  cidr_vpc              = var.cidr_vpc
  cidr_subnet_public_1  = var.cidr_subnet_public_1
  cidr_subnet_public_2  = var.cidr_subnet_public_2
  cidr_subnet_private_1 = var.cidr_subnet_private_1
  cidr_subnet_private_2 = var.cidr_subnet_private_2
}



###############################   Data sources   ###############################



data "aws_availability_zones" "data_source_azs" {
  state = "available"
}



###############################   Application   ###############################



##### Setup VPC

# Create isolated network in the cloud(vpc)
resource "aws_vpc" "vpc" {
  cidr_block = local.cidr_vpc

  tags = {
    Name = "${local.project}-${local.environment}-vpc"
  }
}

# Create the internet entry point for the vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.project}-${local.environment}-igw"
  }
}



##### Setup Public subnets

# Setup multi az public subnets in the vpc(with inbound and outbound traffic)
resource "aws_subnet" "subnet_public_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.cidr_subnet_public_1
  availability_zone = data.aws_availability_zones.data_source_azs.names[0]

  tags = {
    Name = "${local.project}-${local.environment}-subnet-public-1"
  }
}
resource "aws_subnet" "subnet_public_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.cidr_subnet_public_2
  availability_zone = data.aws_availability_zones.data_source_azs.names[1]

  tags = {
    Name = "${local.project}-${local.environment}-subnet-public-2"
  }
}
# Create the route table for the public subnets(targeting internet gateway)
resource "aws_route_table" "route_table_public_subnet" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.project}-${local.environment}-route-table-public-subnet"
  }
}
resource "aws_route_table_association" "route_table_association_public_subnet_1" {
  subnet_id      = aws_subnet.subnet_public_1.id
  route_table_id = aws_route_table.route_table_public_subnet.id
}
resource "aws_route_table_association" "route_table_association_public_subnet_2" {
  subnet_id      = aws_subnet.subnet_public_2.id
  route_table_id = aws_route_table.route_table_public_subnet.id
}



##### Setup Private subnets

# Setup NAT gateways
resource "aws_eip" "eip_nat_1" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "${local.project}-${local.environment}-eip-nat-1"
  }
}
resource "aws_eip" "eip_nat_2" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "${local.project}-${local.environment}-eip-nat-2"
  }
}
resource "aws_nat_gateway" "nat_1" {
  connectivity_type = "public"
  allocation_id     = aws_eip.eip_nat_1.id
  subnet_id         = aws_subnet.subnet_public_1.id

  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.project}-${local.environment}-nat-1"
  }
}
resource "aws_nat_gateway" "nat_2" {
  connectivity_type = "public"
  allocation_id     = aws_eip.eip_nat_2.id
  subnet_id         = aws_subnet.subnet_public_2.id

  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.project}-${local.environment}-nat-2"
  }
}

# Setup multi az private subnets in the vpc(with inbound and outbound traffic)

resource "aws_subnet" "subnet_private_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.cidr_subnet_private_1
  availability_zone = data.aws_availability_zones.data_source_azs.names[0]

  tags = {
    Name = "${local.project}-${local.environment}-subnet-private-1"
  }
}
resource "aws_subnet" "subnet_private_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.cidr_subnet_private_2
  availability_zone = data.aws_availability_zones.data_source_azs.names[1]

  tags = {
    Name = "${local.project}-${local.environment}-subnet-private-2"
  }
}

# Create the route table for the private subnets(targeting nat gateway)

resource "aws_route_table" "route_table_private_subnet_1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "${local.project}-${local.environment}-route-table-private-subnet-1"
  }
}
resource "aws_route_table" "route_table_private_subnet_2" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name = "${local.project}-${local.environment}-route-table-private-subnet-2"
  }
}
resource "aws_route_table_association" "route_table_association_private_subnet_1" {
  subnet_id      = aws_subnet.subnet_private_1.id
  route_table_id = aws_route_table.route_table_private_subnet_1.id
}
resource "aws_route_table_association" "route_table_association_private_subnet_2" {
  subnet_id      = aws_subnet.subnet_private_2.id
  route_table_id = aws_route_table.route_table_private_subnet_2.id
}
