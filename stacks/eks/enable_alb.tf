

data "aws_iam_policy_document" "eks_alb_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_private_cluster.eks.identity.0.oidc.0.issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
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

resource "aws_iam_policy" "alb_controller_policy" {
    name = "AmazonEKSLoadBalancerControllerPolicy"
    policy = file("iam_policies/alb_controller_policy.json")
}

module "alb_controller_role" {
  source = "../../modules/iam_role"
  name = "AmazonEKSLoadBalancerControllerRole"
  policies = ["AmazonEKSLoadBalancerControllerPolicy"]
  assume_role_policy = data.aws_iam_policy_document.eks_alb_assume_role_policy.json
  depends_on = [
    aws_iam_policy.alb_controller_policy
  ]
}