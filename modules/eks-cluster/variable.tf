variable "cluster_name" {
}
variable "cluster_role_arn" {  
}
variable "k8s_version" {
  default = "1.22"
}
variable "subnet_ids" {
}
variable "security_group_ids" {
    default = null
}
variable "endpoint_private_access" {
  default = true
}
variable "endpoint_public_access" {
  default = false
}
variable "public_access_cidrs" {
  default = [
    "0.0.0.0/0"
    ]
}
variable "service_cidr" {
    default = "172.20.0.0/16"
}
variable "enabled_cluster_log_types" {
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}