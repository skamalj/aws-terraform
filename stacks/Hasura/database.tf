resource "aws_security_group" "db_security_group" {
  name   = "db-security-group"
  vpc_id = module.hasura_vpc.vpc.id
}

resource "aws_security_group_rule" "db_allow" {
  security_group_id = aws_security_group.db_security_group.id
  type              = "ingress"
  to_port           = 5432
  from_port         = 5432
  protocol          = "tcp"
  cidr_blocks = [local.ecs_subnet_range]
}

module "aurora_rds" {
  source                    = "../../modules/aurora"
  availability_zones        = data.aws_availability_zones.available.names
  cluster_identifier_prefix = "hasura"
  database_name             = "hasuradb"
  subnet_ids                = module.rds_subnets[*].subnet.id
  master_password           = var.master_password
  deletion_protection       = false
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}
