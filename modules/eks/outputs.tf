output "vpc_id" {
  value = module.eks_vpc.vpc.id
  description = "EKS VPC Id"
}
output "pod_subnets" {
    value =  module.eks_pod_subnets[*].subnet.id
    description = "Pod Subnet IDs"
}

output "oidc_cluster_issuer" {
    value = module.eks_private_cluster.eks.identity.0.oidc.0.issuer
    description = "OIDC Cluster Issuer"
}
output "karpenter_role_arn" {
  value = aws_iam_role.karpenter_controller_role.arn
}

output "node_subnets" {
  value = module.eks_nodes_subnets[*].subnet.id
  description = "Node Subnet IDs"
}

output "public_subnets" {
  value = module.eks_public_subnets[*].subnet.id
  description = "Public Subnet IDs"
}