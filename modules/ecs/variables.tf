variable "name" {
  
}
variable "image" {
  
}
variable "execution_role_arn" {
  
}
variable "target_group_arn" {
  
}
variable "subnets" {
  
}
variable "security_groups" {
  
}
variable "aws_region" {
  
}
variable "log_group" {
  
}
variable "port" {
  default = 80
  description = "Container port"
}
variable "environment" {
  default = null
}
variable "secrets" {
  default = null
  description = "Key Value env variables from secrets"
}
variable "cpu" {
  default = 512
}
variable "memory" {
  default = 2048
}
variable "task_role_arn" {
  default = null
}