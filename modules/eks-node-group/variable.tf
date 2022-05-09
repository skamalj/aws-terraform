variable "cluster_name" {
}
variable "node_role_arn" {  
}
variable "subnet_ids" {
}
variable "desired_size" {
  default = 1
}
variable "min_size" {
  default = 1
}
variable "max_size" {
  default = 3
}
variable "capacity_type" {
  default = "ON_DEMAND"
}
variable "instance_types" {
  default = ["t3.medium"]
}
variable "node_group_name" {
  default = "eks-node-group"
}
variable "tags" {
  default = null
}
variable "max_unavailable" {
  default = 1
}