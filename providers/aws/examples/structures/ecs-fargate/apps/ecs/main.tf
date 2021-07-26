# Implementing ecs with fargate

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
# Create public subnetworks inside the vpc
resource "aws_subnet" "example_subnet_public_1" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "100.100.0.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.0.0 ~ 100.100.0.13) 
  map_public_ip_on_launch = true             # assign a public ip to instances in this subnet
  availability_zone       = "${var.region}b"

  tags = {
    Name = "example_subnet_public_1"
  }
}
resource "aws_subnet" "example_subnet_public_2" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "100.100.1.0/28" # 32-28 = 4 bits for host(must be 0) => (2^4)-2 = 14 addresses for the vpc subnet(100.100.1.0 ~ 100.100.1.13) 
  map_public_ip_on_launch = true             # assign a public ip to instances in this subnet
  availability_zone       = "${var.region}c"

  tags = {
    Name = "example_subnet_public_2"
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
# Associate the route tables to the public subnets
resource "aws_route_table_association" "example_route_table_association_public_subnet_1" {
  subnet_id      = aws_subnet.example_subnet_public_1.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}
resource "aws_route_table_association" "example_route_table_association_public_subnet_2" {
  subnet_id      = aws_subnet.example_subnet_public_2.id
  route_table_id = aws_route_table.example_route_table_public_subnet.id
}

# Create the security group for the tasks containers
resource "aws_security_group" "example_security_group_tasks_instances" {
  name        = "example_security_group_tasks_instances"
  description = "Allow iinbound http/https traffic and all outbound traffic"
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

  egress {
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "example_security_group_tasks_instances"
  }
}


####################################################################################################



# Setup ECS
#TODO : capacity providers?


# Setup ecs service load balancer
# Create the application load balancer
resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example_security_group_tasks_instances.id]
  subnets            = [aws_subnet.example_subnet_public_1.id, aws_subnet.example_subnet_public_2.id]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Name = "example_lb"
  }
}
# Create target group
resource "aws_lb_target_group" "example_target_group" {
  name        = "example-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.example_vpc.id

  depends_on = [aws_lb.example_lb]
}
# Create the listener for lb and target group
resource "aws_lb_listener" "example_lb_listener" {
  load_balancer_arn = aws_lb.example_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_target_group.arn
  }
}



# Create the docker images repository(ECR)
resource "aws_ecr_repository" "example_ecr_repository" {
  name                 = "example_ecr_repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "example_ecr_repository"
  }
}

# Create role for task definition
resource "aws_iam_role" "example_role_task_definition" {
  name = "example_role_task_definition"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "example_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ],
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Name = "example_role_task_definition"
  }
}
# Create a task definition for the example
resource "aws_ecs_task_definition" "example_ecs_task_definition" {
  family                   = "example_ecs_task_definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.example_role_task_definition.arn

  container_definitions = jsonencode([
    {
      name      = "example_ecs_service"
      image     = "${aws_ecr_repository.example_ecr_repository.repository_url}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

}



# Create ecs cluster
resource "aws_ecs_cluster" "example_ecs_cluster" {
  name               = "example_ecs_cluster"
  capacity_providers = ["FARGATE"]

  tags = {
    Name = "example_ecs_cluster"
  }
}

# Create a service in the cluster for task definition
resource "aws_ecs_service" "example_ecs_service" {
  name            = "example_ecs_service"
  cluster         = aws_ecs_cluster.example_ecs_cluster.id
  task_definition = aws_ecs_task_definition.example_ecs_task_definition.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.example_target_group.arn
    container_name   = "example_ecs_service"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.example_subnet_public_1.id, aws_subnet.example_subnet_public_2.id]
    security_groups  = [aws_security_group.example_security_group_tasks_instances.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_target_group.example_target_group
  ]
}
