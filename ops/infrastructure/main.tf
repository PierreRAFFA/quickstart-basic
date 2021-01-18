provider "aws" {
  region  = var.region
  version = "~> 2.3"
}

terraform {
  required_version = ">= 0.12"

  backend "s3" {}
}

####################################################################################
## This should NOT be at the service level but at the common resource level
####################################################################################

# Better to use a custom VPC than the default one
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "vpc" {
  name        = "bark-${var.environment}"
  description = "Access to ECS"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    protocol         = "tcp"
    to_port          = 80
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_availability_zones" "zones" {}

# Should be 1 private subnet per AZ for high availabilty
resource "aws_subnet" "private" {
  count                   = length(data.aws_availability_zones.zones.names)
  cidr_block              = "172.31.${48 + 16 * count.index}.0/20"
  vpc_id                  = aws_default_vpc.default.id
  availability_zone       = data.aws_availability_zones.zones.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name        = "bark-${var.environment}-${data.aws_availability_zones.zones.names[count.index]}-private"
  }
}

resource "aws_ecs_cluster" "common" {
  name = "bark-${var.environment}"
}
####################################################################################