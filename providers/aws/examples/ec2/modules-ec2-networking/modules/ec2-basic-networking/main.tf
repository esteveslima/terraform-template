# Setup networking

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-example"
  }
}

resource "aws_subnet" "example_subnet" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-example"
  }
}

resource "aws_internet_gateway" "example_aws_internet_gateway" {
  vpc_id = aws_vpc.example_vpc.id
}

resource "aws_eip" "example_aws_eip" {
  vpc = true

  instance                  = aws_instance.example_ec2.id
  associate_with_private_ip = "10.0.0.254"
  depends_on                = [aws_internet_gateway.example_aws_internet_gateway]
}

# Setup EC2

resource "aws_instance" "example_ec2" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"

  private_ip = "10.0.0.254"
  subnet_id  = aws_subnet.example_subnet.id

  tags = {
    Name = var.instance_tag
  }
}
