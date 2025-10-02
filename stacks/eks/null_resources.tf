resource "null_resource" "get_cluster_config" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Now deploy application load balancer controller
  provisioner "local-exec" {
    command = <<EOL
        aws eks --region ${data.aws_region.current.region} update-kubeconfig --name ${module.eks_private_cluster.eks.name}
    EOL
  }
}

resource "null_resource" "deploy_albc" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Now deploy application load balancer controller
  provisioner "local-exec" {
    command = <<EOL
        account_id=${local.account_id} enable_alb/aws-load-balancer-controller-service-account.sh | kubectl apply -f -;
        helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${module.eks_private_cluster.eks.name} \
        --set serviceAccount.create=false \
        --set image.repository=602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set enableShield=false \
        --set enableWaf=false \
        --set enableWafv2=false \
        --set region=ap-south-1 \
        --set vpcId=${module.eks_vpc.vpc.id}
    EOL
  }
  depends_on = [
    null_resource.get_cluster_config, resource.aws_eks_fargate_profile.fargate_karpenter
  ]
}

resource "null_resource" "deploy_karpenter_cf_template" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  } 
  provisioner "local-exec" {
    command = <<EOL
        aws cloudformation deploy \
        --stack-name "Karpenter-${module.eks_private_cluster.eks.name}" \
        --template-file "karpenter/karpenter_cf.yaml" \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides ClusterName="${module.eks_private_cluster.eks.name}" eksNodeRole="${module.node_role.role.arn}"
    EOL
  }
  depends_on = [ module.eks_private_cluster ]
}

resource "null_resource" "deploy_karpenter_provisioner" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  
  provisioner "local-exec" {
    command = <<EOL
        CLUSTER_NAME=${var.cluster_name} ./karpenter/provisioner.yaml;
    EOL
  }
  depends_on = [
    null_resource.get_cluster_config,
    null_resource.deploy_karpenter_cf_template,
    resource.helm_release.karpenter
  ]
}
resource "null_resource" "deploy_s3_csi_driver" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Now deploy application load balancer controller
  provisioner "local-exec" {
    command = <<EOL
        helm upgrade --install aws-mountpoint-s3-csi-driver aws-mountpoint-s3-csi-driver/aws-mountpoint-s3-csi-driver \
        --namespace kube-system \
        --set node.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::010526271896:role/AmazonEKS_S3_CSI_DriverRole" \
        --set sidecars.livenessProbe.image.repository="010526271896.dkr.ecr.ap-south-1.amazonaws.com/eks-distro/kubernetes-csi/livenessprobe" \
        --set image.repository="010526271896.dkr.ecr.ap-south-1.amazonaws.com/mountpoint-s3-csi-driver/aws-mountpoint-s3-csi-driver" \
        --set sidecars.nodeDriverRegistrar.image.repository="010526271896.dkr.ecr.ap-south-1.amazonaws.com/eks-distro/kubernetes-csi/node-driver-registrar" \
        --wait;
    EOL
  }
  depends_on = [
    null_resource.get_cluster_config,
    module.s3csi_role
  ]
}
