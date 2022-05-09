output "pod_subnets" {
    value = join("\n", [for s in module.eks_pod_subnets[*] : "${s.subnet.availability_zone}=${s.subnet.id}"])
    description = "Pod Subnet IDs and Availability Zones"
}

output "oidc_cluster_issuer" {
    value = module.eks_private_cluster.eks.identity.0.oidc.0.issuer
    description = "OIDC Cluster Issuer"
}
output "karpenter_role_arn" {
  value = aws_iam_role.karpenter_controller_role.arn
}