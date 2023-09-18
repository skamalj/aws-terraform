
data "aws_iam_policy_document" "eks_cni_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_private_cluster.eks.identity.0.oidc.0.issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_private_cluster.eks.identity.0.oidc.0.issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    principals {
      identifiers = [local.oidc_arb]
      type        = "Federated"
    }
  }
}

module "eks_cni_role" {
  source = "../../modules/iam_role"
  name = "AmazonEKSVPCCNIRole"
  policies = ["AmazonEKS_CNI_Policy"]
  assume_role_policy = data.aws_iam_policy_document.eks_cni_assume_role_policy.json
}