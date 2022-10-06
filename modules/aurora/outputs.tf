output "db_arn" {
  value = aws_rds_cluster.aurora_cluster.arn
}
output "db_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}