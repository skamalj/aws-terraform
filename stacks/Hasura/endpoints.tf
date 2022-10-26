# Create security group for private end points 
resource "aws_security_group" "endpoint_sg" {
  name   = "endpoint_sg"
  vpc_id = module.hasura_vpc.vpc.id
}

resource "aws_security_group_rule" "endpoint_sg_rule" {
  security_group_id = aws_security_group.endpoint_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
}

# Create route table for ecs subnets 
resource "aws_route_table" "endpoint_route_table" {
  vpc_id = module.hasura_vpc.vpc.id
}

# Associate node subnets with endpoint route table
resource "aws_route_table_association" "node_subnet_route_table_association" {
  count          = length(module.ecs_subnets[*].subnet.id)
  subnet_id      = module.ecs_subnets[count.index].subnet.id
  route_table_id = aws_route_table.endpoint_route_table.id
  depends_on = [
    module.ecs_subnets
  ]
}


# Create required endpoints for private cluster
module "ecs_endpoints" {
  source = "../../modules/vpc_endpoint"

  for_each = {
    "com.amazonaws.ap-south-1.s3"      = "Gateway",
    "com.amazonaws.ap-south-1.ecr.api" = "Interface",
    "com.amazonaws.ap-south-1.ecr.dkr" = "Interface",
    "com.amazonaws.ap-south-1.logs"    = "Interface",
    "com.amazonaws.ap-south-1.sts"     = "Interface",
    "com.amazonaws.ap-south-1.secretsmanager"     = "Interface",
    "com.amazonaws.ap-south-1.elasticloadbalancing" = "Interface"
  }
  vpc_endpoint_type  = each.value
  service_name       = each.key
  vpc_id             = module.hasura_vpc.vpc.id
  security_group_ids = [aws_security_group.endpoint_sg.id]
  route_table_ids    = [aws_route_table.endpoint_route_table.id]
  subnet_ids         = [module.ecs_subnets[0].subnet.id]
}