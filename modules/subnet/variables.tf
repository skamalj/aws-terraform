variable "cidr_block" {
}
variable "availability_zone" {
}
variable "vpc_id" {
}
variable "name" {
}
variable "is_public" {
  default = false
}
variable "enable_resource_name_dns_a_record_on_launch" {
    default = true
}
variable "tags" {
  default = {}
}

