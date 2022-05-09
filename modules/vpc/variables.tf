variable "cidr_block" {
}
variable "enable_dns_hostnames" {
    default = true
}
variable "enable_dns_support" {
    default = true
}
variable "name" {
}
variable "tags" {
  default = {}
}
variable "secondary_cidrs" {
  default = []
}
