terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.12.1"
    }
  }
}


resource "aws_eks_node_group" "eks_ng" {
  cluster_name     = var.cluster_name
  node_role_arn = var.node_role_arn
  scaling_config {
    desired_size = var.desired_size
    max_size = var.max_size
    min_size = var.min_size
  }
  subnet_ids = var.subnet_ids
  capacity_type = var.capacity_type
  instance_types = var.instance_types
  node_group_name = var.node_group_name
  tags = var.tags
  update_config {
    max_unavailable = var.max_unavailable
  }
}