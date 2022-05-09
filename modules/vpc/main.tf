terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.12.1"
    }
  }
}


resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support
  tags = merge(var.tags, {Name = var.name})
}

# Attached secondary IP ranges for master
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  for_each = toset(var.secondary_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value
}
