variable "cluster_name" {
  
}
variable "primary_vpc_cidr" {
}
variable "node_cidr" {
}
variable "pod_cidr" {
}
variable "public_cidr" {
}
variable "endpoint_public_access" {
  default = true
}
variable "master_password" {
  
}
variable "deletion_protection" {
  default = false
}