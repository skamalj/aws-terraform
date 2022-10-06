terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.32.0"
    }
  }
}

resource "aws_rds_cluster_parameter_group" "parameter_group" {
  name   = join("-", [var.cluster_identifier_prefix, var.family])
  family = var.family
}
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = join("-", [var.cluster_identifier_prefix, var.family])
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "aurora_cluster" {
  availability_zones                  = var.availability_zones
  backup_retention_period             = var.backup_retention_period
  cluster_identifier_prefix           = var.cluster_identifier_prefix
  database_name                       = var.database_name
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.parameter_group.name
  db_subnet_group_name                = aws_db_subnet_group.db_subnet_group.name
  deletion_protection                 = var.deletion_protection
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  engine                              = var.engine
  engine_mode                         = var.engine_mode
  engine_version                      = var.engine_version
  enable_global_write_forwarding      = var.enable_global_write_forwarding
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  kms_key_id                          = var.kms_key_id
  master_password                     = var.master_password
  master_username                     = var.master_username
  preferred_backup_window             = var.preferred_backup_window
  preferred_maintenance_window        = var.preferred_maintenance_window
  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = 0.5
  }
  skip_final_snapshot = var.skip_final_snapshot
  storage_encrypted   = var.storage_encrypted
  vpc_security_group_ids = var.vpc_security_group_ids
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier  = aws_rds_cluster.aurora_cluster.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora_cluster.engine
  engine_version      = aws_rds_cluster.aurora_cluster.engine_version
  publicly_accessible = var.publicly_accessible
lifecycle {
  ignore_changes = [
    cluster_identifier
  ]
}
}
