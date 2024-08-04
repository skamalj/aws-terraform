# Create security group for private end points 
resource "aws_security_group" "endpoint_sg" {
  name   = "endpoint_sg"
  vpc_id = module.eks_vpc.vpc.id
}

resource "aws_security_group_rule" "endpoint_sg_rule" {
  security_group_id = aws_security_group.endpoint_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.node_cidr, var.primary_vpc_cidr, var.pod_cidr]
}

# Create route table for private subnets 
resource "aws_route_table" "endpoint_route_table" {
  vpc_id = module.eks_vpc.vpc.id
}

# Associate subnets with main route table
resource "aws_route_table_association" "endpoint_route_table_association" {
  subnet_id      = module.eks_endpoint_subnet.subnet.id
  route_table_id = aws_route_table.endpoint_route_table.id
}

# Associate node subnets with endpoint route table
resource "aws_route_table_association" "node_subnet_route_table_association" {
  count          = length(module.eks_nodes_subnets[*].subnet.id)
  subnet_id      = module.eks_nodes_subnets[count.index].subnet.id
  route_table_id = aws_route_table.endpoint_route_table.id
  depends_on = [
    module.eks_nodes_subnets
  ]
}

# Associate Pod subnets with endpoint route table
resource "aws_route_table_association" "pod_subnet_route_table_association" {
  count          = length(module.eks_pod_subnets[*].subnet.id)
  subnet_id      = module.eks_pod_subnets[count.index].subnet.id
  route_table_id = aws_route_table.endpoint_route_table.id
  depends_on = [
    module.eks_nodes_subnets
  ]
}


# Create required endpoints for private cluster
module "eks_endpoints" {
  source = "../../modules/vpc_endpoint"

  for_each = {
    "com.amazonaws.ap-south-1.s3"      = "Gateway",
    "com.amazonaws.ap-south-1.ec2"     = "Interface",
    "com.amazonaws.ap-south-1.ecr.api" = "Interface",
    "com.amazonaws.ap-south-1.ecr.dkr" = "Interface",
    "com.amazonaws.ap-south-1.logs"    = "Interface",
    "com.amazonaws.ap-south-1.sts"     = "Interface",
    "com.amazonaws.ap-south-1.sqs"     = "Interface",
    # Required by ALBC for private nodes
    "com.amazonaws.ap-south-1.elasticloadbalancing" = "Interface"
    # Required by Karpenter for private nodes
    "com.amazonaws.ap-south-1.ssm"     = "Interface",
  }
  vpc_endpoint_type  = each.value
  service_name       = each.key
  vpc_id             = module.eks_vpc.vpc.id
  security_group_ids = [aws_security_group.endpoint_sg.id]
  route_table_ids    = [aws_route_table.endpoint_route_table.id]
  subnet_ids         = [module.eks_endpoint_subnet.subnet.id]
}