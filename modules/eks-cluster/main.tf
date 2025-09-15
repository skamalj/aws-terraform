terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.12.1"
    }
  }
}


resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version = var.k8s_version
  enabled_cluster_log_types = var.enabled_cluster_log_types
  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access = var.endpoint_public_access
    public_access_cidrs = var.public_access_cidrs
  }
  kubernetes_network_config {
    service_ipv4_cidr = var.service_cidr
  }
}

resource "aws_security_group_rule" "all_egress" {
  security_group_id = tolist(aws_eks_cluster.eks_cluster.vpc_config[0].security_group_ids)[0]
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

