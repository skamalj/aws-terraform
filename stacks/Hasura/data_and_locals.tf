data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}


locals {
  account_id = data.aws_caller_identity.current.account_id
  // Take /24 range from primary to use for cluster subnets. 
  // This will be used to create 3 /28 ranges for the cluster subnets.
  lb_subnet_range = cidrsubnet(var.primary_vpc_cidr, 8, 0)
  // Range for endpoint subnet
  ecs_subnet_range = cidrsubnet(var.primary_vpc_cidr, 8, 1)
  // Range for private LBs
  rds_subnet_range = cidrsubnet(var.primary_vpc_cidr, 8, 2)
  //Hasura Env
  hasura_env = [
    {
      name  = "HASURA_GRAPHQL_ENABLE_CONSOLE"
      value = "true"
    },
    {
      name  = "HASURA_GRAPHQL_DEV_MODE"
      value = "true"
    },
    {
      name  = "HASURA_GRAPHQL_DATABASE_URL"
      value = "postgres://dbadmin:${var.master_password}@${module.aurora_rds.db_endpoint}:5432/hasuradb"
    }
  ]
}
