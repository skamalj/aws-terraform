data "aws_iam_policy_document" "efs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_cluster.oidc_cluster_issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:efs-ns:efs-csi-controller-sa"]
    }
    principals {
      identifiers = [local.oidc_arb]
      type        = "Federated"
    }
  }
}

module "efs_role" {
  source = "../../modules/iam_role"
  name = "AmazonEKS_EFS_CSI_DriverRole"
  policies = ["AmazonEKS_EFS_CSI_Driver_Policy"]
  assume_role_policy = data.aws_iam_policy_document.efs_assume_role_policy.json
}

