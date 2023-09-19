#data "aws_iam_policy" "ssm_managed_instance" {
#  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#}
#
#resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
#  role       = module.node_role.role.name
#  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
#}
#
#resource "aws_iam_instance_profile" "karpenter" {
#  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
#  role = module.node_role.role.name
#}

#resource "aws_iam_policy" "karpenter_controller_policy" {
#  name = "karpenter-policy-${var.cluster_name}"
#  
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = [
#          "ec2:CreateLaunchTemplate",
#          "ec2:DeleteLaunchTemplate",
#          "ec2:CreateFleet",
#          "ec2:RunInstances",
#          "ec2:CreateTags",
#          "iam:PassRole",
#          "ec2:TerminateInstances",
#          "ec2:DescribeLaunchTemplates",
#          "ec2:DescribeInstances",
#          "ec2:DescribeSecurityGroups",
#          "ec2:DescribeSubnets",
#          "ec2:DescribeInstanceTypes",
#          "ec2:DescribeInstanceTypeOfferings",
#          "ec2:DescribeAvailabilityZones",
#          "ssm:GetParameter"
#        ]
#        Effect   = "Allow"
#        Resource = "*"
#      },
#    ]
#  })
#}

data "aws_iam_policy_document" "karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "karpenter_controller_role" {
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json
  name               = "karpenter-controller-${var.cluster_name}"
}

resource "aws_iam_role_policy_attachment" "karpenter_role_policy_attachment" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = "arn:aws:iam::${local.account_id}:policy/KarpenterControllerPolicy-${var.cluster_name}"
}
