

data "aws_iam_policy_document" "eks_s3csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_private_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:s3-csi-driver-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_private_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [local.oidc_arb]
    }
  }
}



resource "aws_iam_policy" "s3csi_policy" {
    name = "AmazonS3CSIDriverPolicy"
    policy = templatefile("iam_policies/s3csi_policy.json.tpl", {
      bucket_name = var.s3_bucket_name_for_models
    })
}

module "s3csi_role" {
  source = "../../modules/iam_role"
  name = "AmazonEKS_S3_CSI_DriverRole"
  policies = ["AmazonS3CSIDriverPolicy"]
  assume_role_policy = data.aws_iam_policy_document.eks_s3csi_assume_role_policy.json
  depends_on = [
    aws_iam_policy.s3csi_policy
  ]
}
