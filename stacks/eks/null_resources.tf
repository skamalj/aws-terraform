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
    null_resource.get_cluster_config
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
}

resource "null_resource" "deploy_karpenter" {
  # Run this provisioner always
  triggers = {
    always_run = timestamp()
  }  # Now deploy application load balancer controller
  provisioner "local-exec" {
    command = <<EOL
        helm upgrade --install  karpenter oci://public.ecr.aws/karpenter/karpenter \
        --namespace karpenter --create-namespace \
        --version 0.37.0 \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${local.account_id}:role/karpenter-controller-${module.eks_private_cluster.eks.name} \
        --set settings.clusterName=${module.eks_private_cluster.eks.name} \
        --set settings.interruptionQueue=${module.eks_private_cluster.eks.name} \
        --set settings.clusterEndpoint=${module.eks_private_cluster.eks.endpoint} \
        --set settings.isolatedVPC="true" \
        --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${module.eks_private_cluster.eks.name} \
        --set controller.resources.requests.cpu=1 \
        --set controller.resources.requests.memory=1Gi \
        --set controller.resources.limits.cpu=1 \
        --set controller.resources.limits.memory=1Gi \
        --set controller.image.repository=${local.account_id}.dkr.ecr.ap-south-1.amazonaws.com/karpenter_controller \
        --set controller.image.digest="sha256:cbf46e9a2985cfb84e21fbcc58efff0e8a2de79943a4a63daf0401da9fceb78e"  \
        --wait; \
        CLUSTER_NAME=${var.cluster_name} ./karpenter/provisioner.yaml;
    EOL
  }
  depends_on = [
    null_resource.get_cluster_config,
    null_resource.deploy_karpenter_cf_template
  ]
}
