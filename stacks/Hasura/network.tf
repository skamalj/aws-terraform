## Create VPC with primary and seconday CIDR blocks
module "hasura_vpc" {
  source     = "../../modules/vpc"
  cidr_block = var.primary_vpc_cidr
  name       = "hasura_vpc"
}

## Now create subnets for - LB, ECS and RDS.
module "lb_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.lb_subnet_range, 4, count.index)
  vpc_id            = module.hasura_vpc.vpc.id
  is_public         = true
  name              = join("-", ["hasura-lb", data.aws_availability_zones.available.names[count.index]])
}

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = module.hasura_vpc.vpc.id
  tags = {
    Name = "hasura-vpc-igw"
  }
}
# Associate IGW with route table
resource "aws_route_table" "public_route_table" {
  vpc_id = module.hasura_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "lb_subnets_route_table" {
  count          = length(module.lb_subnets[*])
  subnet_id      = module.lb_subnets[count.index].subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

module "ecs_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.ecs_subnet_range, 4, count.index)
  vpc_id            = module.hasura_vpc.vpc.id
  name              = join("-", ["hasura-ecs", data.aws_availability_zones.available.names[count.index]])
}

module "rds_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.rds_subnet_range, 4, count.index)
  vpc_id            = module.hasura_vpc.vpc.id
  name              = join("-", ["hasura-rds", data.aws_availability_zones.available.names[count.index]])
}

# Create security group for ALB 
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = module.hasura_vpc.vpc.id
}

resource "aws_security_group_rule" "alb_sg_rule_allow_80" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "alb_sg_rule_default_egress" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


module "nlb" {
  source  = "../../modules/nlb"
  name    = var.name
  vpc_id  = module.hasura_vpc.vpc.id
  subnets = module.lb_subnets[*].subnet.id
  port    = var.port
}

module "nlb-int" {
  source  = "../../modules/nlb"
  name    = join("-",[var.name,"int"])
  vpc_id  = module.hasura_vpc.vpc.id
  subnets = module.lb_subnets[*].subnet.id
  port    = var.port
  is_internal = true
}

# Create security group for private end points 
resource "aws_security_group" "ecs_sg" {
  name   = "ecs_sg"
  vpc_id = module.hasura_vpc.vpc.id
}

resource "aws_security_group_rule" "ecs_sg_rule_allow_80" {
  security_group_id = aws_security_group.ecs_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
}


resource "aws_security_group_rule" "ecs_sg_rule_default_egress" {
  security_group_id = aws_security_group.ecs_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.primary_vpc_cidr]
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}
resource "aws_security_group_rule" "ecs_sg_rule_s3_gateway_egress" {
  security_group_id = aws_security_group.ecs_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
}

