# Deploy application load balancer
resource "null_resource" "get_cluster_config" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Now deploy application load balancer controller
  provisioner "local-exec" {
    command = <<EOL
        aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks_private_cluster.eks.name}
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
        account_id=${local.account_id} ${path.module}/enable_alb/aws-load-balancer-controller-service-account.sh | kubectl apply -f -;
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
    null_resource.get_cluster_config
  ]
}

resource "null_resource" "deploy_karpenter" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Now deploy application load balancer controller
  provisioner "local-exec" {
    command = <<EOL
        helm upgrade --install --namespace karpenter --create-namespace \
        karpenter karpenter/karpenter \
        --version v0.9.1 \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${local.account_id}:role/karpenter-controller-${module.eks_private_cluster.eks.name} \
        --set clusterName=${module.eks_private_cluster.eks.name} \
        --set clusterEndpoint=${module.eks_private_cluster.eks.endpoint} \
        --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${module.eks_private_cluster.eks.name} \
        --set controller.image=${local.account_id}.dkr.ecr.ap-south-1.amazonaws.com/karpenter_controller:v0.9.1 \
        --set webhook.image=${local.account_id}.dkr.ecr.ap-south-1.amazonaws.com/karpenter_webhook:v0.9.1 \
        --wait;
        CLUSTER_NAME=${var.cluster_name} ${path.module}/karpenter/provisioner.yaml | kubectl apply -f -;
    EOL
  }
  depends_on = [
    null_resource.get_cluster_config
  ]
}