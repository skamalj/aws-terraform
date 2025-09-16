terraform {
  backend "s3" {
    key    = "devtest/tf/eks"
    region = "ap-south-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.16.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = ">= 3.3.0"
    }
  }
}

# This is used to generate thumbprint for OIDC provider configuration
provider "tls" {
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  profile = "skamalj-dev"
}



## Create required roles for EKS - ClusterRole, NodeRole , ALB Controller Role
module "cluster_role" {
  source             = "../../modules/iam_role"
  name               = "eksClusterRole"
  policies           = ["AmazonEKSClusterPolicy", "AmazonEKSVPCResourceController"]
  assume_role_policy = file("iam_policies/cluster_assume_role_policy.json")
}

module "node_role" {
  source             = "../../modules/iam_role"
  name               = "eksNodeRole"
  policies           = ["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryReadOnly"]
  assume_role_policy = file("iam_policies/node_assume_role_policy.json")
}

# Additional security groups cannot be attached later on, so this one is created and attached. Rules can be added later.
# EKS creates it's own security group to communicate with nodes.
resource "aws_security_group" "user_eks_sg" {
  name   = "user-eks-sg"
  vpc_id = module.eks_vpc.vpc.id
}

module "eks_private_cluster" {
  source                 = "../../modules/eks-cluster"
  cluster_name           = var.cluster_name
  cluster_role_arn       = module.cluster_role.role.arn
  subnet_ids             = module.eks_cluster_subnets[*].subnet.id
  security_group_ids     = [aws_security_group.user_eks_sg.id]
  endpoint_public_access = var.endpoint_public_access
  k8s_version = var.k8s_version
}

module "eks_node_group_1" {
  source        = "../../modules/eks-node-group"
  cluster_name  = var.cluster_name
  instance_types = var.instance_types
  node_role_arn = module.node_role.role.arn
  subnet_ids    = module.eks_nodes_subnets[*].subnet.id
  depends_on = [
    module.eks_private_cluster
  ]
}

data "tls_certificate" "eks_oidc_issuer" {
  url = module.eks_private_cluster.eks.identity.0.oidc.0.issuer
}

# Create OIDC provider for EKS in IAM, to facilitate linking serviceaccount with IAM role. 
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_issuer.certificates[0].sha1_fingerprint]
  url             = module.eks_private_cluster.eks.identity.0.oidc.0.issuer
}

resource "aws_ec2_tag" "eks_cluster_sg_tag" {
  resource_id = data.aws_security_groups.eks_sg.ids[0]

  key   = "karpenter.sh/discovery"
  value = var.cluster_name
}

data "aws_security_groups" "eks_sg" {
  tags =  {
     "kubernetes.io/cluster/${var.cluster_name}" =  "owned"
  }
  depends_on = [ module.eks_private_cluster ]
}
