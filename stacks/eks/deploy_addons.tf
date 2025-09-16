resource "aws_eks_addon" "enable_s3csi_driver" {
  cluster_name = module.eks_private_cluster.eks.name
  addon_name   = "aws-mountpoint-s3-csi-driver"
}
