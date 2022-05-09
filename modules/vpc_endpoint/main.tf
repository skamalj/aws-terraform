terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.12.1"
    }
  }
}


resource "aws_vpc_endpoint" "endpoint" {
  vpc_endpoint_type = var.vpc_endpoint_type
  service_name = var.service_name
  vpc_id = var.vpc_id
  policy = var.policy
  private_dns_enabled = var.vpc_endpoint_type == "Interface" ? true : null
  route_table_ids = var.vpc_endpoint_type == "Gateway" ? var.route_table_ids : []
  subnet_ids =  var.vpc_endpoint_type == "Interface" ?   var.subnet_ids : []
  security_group_ids = var.vpc_endpoint_type == "Interface" ? var.security_group_ids : []
  tags = var.tags
}
 
