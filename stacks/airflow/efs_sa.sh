cat <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: aws-efs-csi-driver
  name: efs-csi-controller-sa
  namespace: efs-ns
  annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::${account_id}:role/AmazonEKS_EFS_CSI_DriverRole
EOF
