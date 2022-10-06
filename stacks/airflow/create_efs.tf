resource "aws_security_group" "efs_security_group" {
  name   = "efs-security-group"
  vpc_id = module.eks_cluster.vpc_id
}

resource "aws_security_group_rule" "efs_allow" {
  security_group_id = aws_security_group.efs_security_group.id
  type              = "ingress"
  to_port           = 2049
  from_port         = 2049
  protocol          = "tcp"
  cidr_blocks = [var.node_cidr, var.pod_cidr]
}

resource "aws_efs_file_system" "airflow" {
}

resource "aws_efs_mount_target" "airflow_eks_mnt_targets" {
  count  = length(data.aws_availability_zones.available.names)
  file_system_id = aws_efs_file_system.airflow.id
  subnet_id      = module.eks_cluster.node_subnets[count.index]
  security_groups = [aws_security_group.efs_security_group.id]
}