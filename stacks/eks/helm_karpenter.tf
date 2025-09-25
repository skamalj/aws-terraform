resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  create_namespace = true

  repository = "oci://public.ecr.aws/karpenter/"
  chart      = "karpenter"
  version    = "1.7.1"

  set = [{
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${local.account_id}:role/karpenter-controller-${module.eks_private_cluster.eks.name}"
  },

 {
    name  = "settings.clusterName"
    value = module.eks_private_cluster.eks.name
  },

 {
    name  = "settings.interruptionQueue"
    value = module.eks_private_cluster.eks.name
  },
  {
    name  = "settings.clusterEndpoint"
    value = module.eks_private_cluster.eks.endpoint
  },
  {
    name  = "settings.isolatedVPC"
    value = "true"
  },
  {
    name  = "settings.aws.defaultInstanceProfile"
    value = "KarpenterNodeInstanceProfile-${module.eks_private_cluster.eks.name}"
  },
  {
    name  = "controller.resources.requests.cpu"
    value = "1"
  },
  {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  },
  {
    name  = "controller.resources.limits.cpu"
    value = "1"
  },
  {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  },
  {
    name  = "controller.image.repository"
    value = "${local.account_id}.dkr.ecr.ap-south-1.amazonaws.com/karpenter_controller"
  },
  {
    name  = "controller.image.digest"
    value = "sha256:0a2b4f6364582dd0ffdf8dfe7f05d5b0e531ccdbb9e035fea3b316b5f5c72935"
  }]

  # optionally wait until resources are ready
  wait = true

  depends_on = [
    null_resource.get_cluster_config,
    null_resource.deploy_karpenter_cf_template
  ]
}
