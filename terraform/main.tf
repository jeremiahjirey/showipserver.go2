terraform {
    required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.96.0"
    }
    random = {
        source = "hashicorp/random"
        version = "~> 3.0"
    }
    }
}

provider "aws" {
    region = "us-east-1"
}

#########################
# VPC DAN SUBNET
#########################

resource "aws_vpc" "go_vpc" {
    cidr_block           = "25.1.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "go-vpc"
    }
}

resource "aws_vpc_ipv6_cidr_block_association" "ipv6ass" {
    vpc_id = aws_vpc.go_vpc.id
    assign_generated_ipv6_cidr_block = "true"
}

resource "aws_internet_gateway" "go_igw" {
    vpc_id = aws_vpc.go_vpc.id
    tags = {
    Name = "go-igw"
    }
}

resource "aws_subnet" "go_public_a" {
    vpc_id                  = aws_vpc.go_vpc.id
    cidr_block              = "25.1.0.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
    tags = {
    Name = "go-public-subnet-a"
    }
}

resource "aws_subnet" "go_public_b" {
    vpc_id                  = aws_vpc.go_vpc.id
    cidr_block              = "25.1.2.0/24"
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = true
    tags = {
    Name = "go-public-subnet-b"
    }
}

resource "aws_subnet" "go_private_a" {
    vpc_id            = aws_vpc.go_vpc.id
    cidr_block        = "25.1.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
    Name = "go-private-subnet-a"
    }
}

resource "aws_subnet" "go_private_b" {
    vpc_id            = aws_vpc.go_vpc.id
    cidr_block        = "25.1.3.0/24"
    availability_zone = "us-east-1b"
    tags = {
    Name = "go-private-subnet-b"
    }
}

resource "aws_eip" "go_nat_eip" {
    vpc = true
}

resource "aws_nat_gateway" "go_nat" {
    allocation_id = aws_eip.go_nat_eip.id
    subnet_id     = aws_subnet.go_public_a.id
    tags = {
    Name = "go-nat"
    }
}

resource "aws_route_table" "go_public_rt" {
    vpc_id = aws_vpc.go_vpc.id

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.go_igw.id
    }

    tags = {
        Name = "go-public"
    }
}

resource "aws_route_table_association" "go_public_assoc_a" {
    subnet_id      = aws_subnet.go_public_a.id
    route_table_id = aws_route_table.go_public_rt.id
}

resource "aws_route_table_association" "go_public_assoc_b" {
    subnet_id      = aws_subnet.go_public_b.id
    route_table_id = aws_route_table.go_public_rt.id
}

resource "aws_route_table" "go_private_rt" {
    vpc_id = aws_vpc.go_vpc.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.go_nat.id
    }

    tags = {
        Name = "go-private"
    }
}

resource "aws_route_table_association" "go_private_assoc_a" {
    subnet_id      = aws_subnet.go_private_a.id
    route_table_id = aws_route_table.go_private_rt.id
}

resource "aws_route_table_association" "go_private_assoc_b" {
    subnet_id      = aws_subnet.go_private_b.id
    route_table_id = aws_route_table.go_private_rt.id
}

#########################
# SECURITY GROUPS
#########################

resource "aws_security_group" "go_sg_app" {
    name   = "go-sg"
    vpc_id = aws_vpc.go_vpc.id

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "go-sg-apps"
    }
}

#############################
# ELASTIC CONTAINER REGISTRY#
#############################
resource "aws_ecr_repository" "goecr" {
  name                 = "goecr25"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}

#######
# EKS #
#######
data "aws_iam_role" "existing_lab_role" {
    name = "LabRole"
}

resource "aws_eks_cluster" "cluster" {
  name = "clusterGo"

  access_config {
    authentication_mode = "API"
  }

  role_arn = "arn:aws:iam::778876534404:role/LabRole"
  version  = "1.32"

  vpc_config {
    subnet_ids = [
      aws_subnet.go_public_a.id,
      aws_subnet.go_public_b.id,
    ]
  }
}

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "go-worker"
  node_role_arn   = "arn:aws:iam::778876534404:role/LabRole"
  subnet_ids = [
      aws_subnet.go_public_a.id,
      aws_subnet.go_public_b.id,
    ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  update_config {
    max_unavailable = 1
  }
}
