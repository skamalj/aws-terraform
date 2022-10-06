variable "availability_zones" {
  description = "List of availability zones"
}
variable "cluster_identifier_prefix" {

}
variable "database_name" {

}
variable "subnet_ids" {
  type = list
}
variable "vpc_security_group_ids" {
  type = list
}
variable "deletion_protection" {
  default = true
}
variable "backup_retention_period" {
  default = 7
}
variable "enabled_cloudwatch_logs_exports" {
  default = ["postgresql"]
  description = "Other values are audit,error, general, slowquery"
}
variable "family" {
  default = "aurora-postgresql13"
}
variable "engine" {
  default     = "aurora-postgresql"
  description = "Valid Values: aurora, aurora-mysql, aurora-postgresql, mysql, postgres"
}
variable "engine_mode" {
  default     = "provisioned"
  description = "Valid valiues: multimaster, parallelquery, provisioned, serverless"
}
variable "engine_version" {
  default = "13.7"
}
variable "enable_global_write_forwarding" {
  default = false
}
variable "iam_database_authentication_enabled" {
  default = true
}
variable "kms_key_id" {
  default = null
}
variable "master_username" {
  default = "dbadmin"
}
variable "master_password" {
  
}
variable "preferred_maintenance_window" {
  default = "mon:01:00-mon:01:30"
}
variable "preferred_backup_window" {
  default = "02:00-03:00"
}
variable "max_capacity" {
  default = 10
}
variable "skip_final_snapshot" {
  default = true
}
variable "storage_encrypted" {
  default = true
}
variable "publicly_accessible" {
  default = true
}
