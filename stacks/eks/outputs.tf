output "pod_subnets" {
    value =  [for s in module.eks_pod_subnets : join("=",[s.subnet.availability_zone,s.subnet.id])]
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