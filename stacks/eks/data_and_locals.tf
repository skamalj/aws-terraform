data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  oidc_arb = join("", [
        "arn:aws:iam::", data.aws_caller_identity.current.account_id, 
        ":oidc-provider/",replace(module.eks_private_cluster.eks.identity.0.oidc.0.issuer, "https://", "")
        ])
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  // Take /24 range from primary to use for cluster subnets. 
  // This will be used to create 3 /28 ranges for the cluster subnets.
  cluster_subnet_range = cidrsubnet(var.primary_vpc_cidr, 8, 0)
  // Range for endpoint subnet
  endpoint_subnet_range = cidrsubnet(var.primary_vpc_cidr, 8, 1)
  // Range for private LBs
  lb_subnet_range = cidrsubnet(var.primary_vpc_cidr, 8, 2)
}
