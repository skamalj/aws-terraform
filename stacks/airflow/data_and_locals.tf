data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  oidc_arb = join("", [
        "arn:aws:iam::", data.aws_caller_identity.current.account_id, 
        ":oidc-provider/",replace(module.eks_cluster.oidc_cluster_issuer, "https://", "")
        ])
}