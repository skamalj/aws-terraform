provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "kuberay_operator" {
  name       = "kuberay-operator"
  namespace  = "default" # change if you want it in another namespace
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "kuberay-operator"
  version    = "1.4.2"

  set = [{
    name  = "image.repository"
    value = "010526271896.dkr.ecr.ap-south-1.amazonaws.com/kuberay/operator"
  },
  {
    name  = "image.tag"
    value = "v1.4.2"
  }]

  wait = true
  depends_on = [
    null_resource.get_cluster_config
  ]
}
