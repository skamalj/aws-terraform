terraform {
  backend "s3" {
    key    = "devtest/tf/airflow"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.12.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.3.0"
    }
  }
}

# This is used to generate thumbprint for OIDC provider configuration
provider "tls" {
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}


module "eks_cluster" {
  source                 = "../../modules/eks"
  cluster_name           = var.cluster_name
  primary_vpc_cidr       = var.primary_vpc_cidr
  node_cidr              = var.node_cidr
  pod_cidr               = var.pod_cidr
  public_cidr            = var.public_cidr
  endpoint_public_access = var.endpoint_public_access
}

module "aurora_rds" {
  source                    = "../../modules/aurora"
  availability_zones        = data.aws_availability_zones.available.names
  cluster_identifier_prefix = "airflow"
  database_name             = "airflowdb"
  subnet_ids                = module.eks_cluster.public_subnets
  master_password           = var.master_password
  deletion_protection       = var.deletion_protection
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

resource "aws_security_group" "db_security_group" {
  name   = "db-security-group"
  vpc_id = module.eks_cluster.vpc_id
}

resource "aws_security_group_rule" "db_allow" {
  security_group_id = aws_security_group.db_security_group.id
  type              = "ingress"
  to_port           = 5432
  from_port         = 5432
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_eip" "nat_ip" {
 }

##Create NAT gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_ip.allocation_id
  subnet_id     = module.eks_cluster.public_subnets[0]
}

data "aws_route_table" "eks_route_table" {
  subnet_id = module.eks_cluster.node_subnets[0]
  depends_on = [
    module.eks_cluster
  ]
}

## Associate NGW with route table
resource "aws_route" "public_route_for_nodes" {
    route_table_id = data.aws_route_table.eks_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
} 


