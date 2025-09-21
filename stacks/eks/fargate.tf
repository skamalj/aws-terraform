resource "aws_iam_role" "fargate_role" {
  name = "eks-fargate-profile-policy"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicyAttach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_role.name
}

resource "aws_eks_fargate_profile" "fargate_karpenter" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "fargate_karpenter"
  pod_execution_role_arn = aws_iam_role.fargate_role.arn
  subnet_ids             = module.eks_pod_subnets[*].subnet.id

  selector {
    namespace = "karpenter"
  }
    depends_on = [
    module.eks_private_cluster
  ]
}

resource "aws_eks_fargate_profile" "fargate_system" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "fargate_system"
  pod_execution_role_arn = aws_iam_role.fargate_role.arn
  subnet_ids             = module.eks_pod_subnets[*].subnet.id

  selector {
    namespace = "system"
  }
  depends_on = [
    module.eks_private_cluster
  ]
}