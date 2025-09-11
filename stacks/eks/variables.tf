variable "cluster_name" {
  default     = "dev"
}
variable "primary_vpc_cidr" {
  default     = "10.0.0.0/16"
}
variable "node_cidr" {
  default     = "10.1.0.0/16"
}
variable "pod_cidr" {
  default     = "10.2.0.0/16"
}
variable "public_cidr" {
  default     = "10.3.0.0/16"
}
variable "endpoint_public_access" {
  default = true
}
variable "k8s_version" {
  default = "1.33"
}
variable "instance_types" {
  default = ["p5.4xlarge"]
}