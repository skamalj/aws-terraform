variable "vpc_endpoint_type" {
}
variable "service_name" {
}
variable "vpc_id" {
}
variable "policy" {
  default = null
}
variable "route_table_ids" {
  default = []
}
variable "subnet_ids" {
    default = []
}
variable "security_group_ids" {
    default = []
}
variable "tags" {
  default = null
}

