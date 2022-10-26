variable "name" {
}
variable "vpc_id" {
}
variable "subnets" {
  description = "List of subnet Ids for NLB"
}
variable "port" {
  description = "Port at which target listens"
  default = 80
}
variable "listen_port" {
  description = "Port at which LB recieves client requests"
  default = 80
} 
variable "protocol" {
  default = "TCP"
}
variable "is_internal" {
  default = false
}
variable "access_logs_bucket" {
  default = null
}
variable "enable_cross_zone_load_balancing" {
  default = true
}