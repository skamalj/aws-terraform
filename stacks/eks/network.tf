## Create VPC with primary and seconday CIDR blocks
module "eks_vpc" {
  source          = "../../modules/vpc"
  cidr_block      = var.primary_vpc_cidr
  name            = "eks_vpc"
  secondary_cidrs = [var.node_cidr, var.pod_cidr, var.public_cidr]
}

## Now create subnets for - Cluster, Nodes, Pods, Endpoints and  Load Balancer. Load balancer subnet is public 
## while all others are Private.  Internal LBs are created in node subnets.
module "eks_cluster_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.cluster_subnet_range, 4, count.index)
  vpc_id            = module.eks_vpc.vpc.id
  name              = join("-", ["eks-cluster", data.aws_availability_zones.available.names[count.index]])
  depends_on = [
    module.eks_vpc
  ]
}

module "eks_nodes_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.node_cidr, 4, count.index)
  vpc_id            = module.eks_vpc.vpc.id
  name              = join("-", ["eks-nodes", data.aws_availability_zones.available.names[count.index]])
  tags = {
    "karpenter/eks-node-subnet"                 = "1"
  }
  depends_on = [
    module.eks_vpc
  ]
}

## This is for interneal loadbalancers
module "eks_lb_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.lb_subnet_range, 2, count.index)
  vpc_id            = module.eks_vpc.vpc.id
  name              = join("-", ["eks-internal-elb", data.aws_availability_zones.available.names[count.index]])
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned",
    "kubernetes.io/role/internal-elb"           = "1"
  }
  depends_on = [
    module.eks_vpc
  ]
}

## Create public Subnets. This still does not provide any internet egress for private subnets
## This is only for External Load Balancers
module "eks_public_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.public_cidr, 4, count.index)
  vpc_id            = module.eks_vpc.vpc.id
  is_public         = true
  name              = join("-", ["eks-public", data.aws_availability_zones.available.names[count.index]])
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned",
    "kubernetes.io/role/elb"                    = "1"
  }
  depends_on = [
    module.eks_vpc
  ]
}

## IGW to provide route for public subnets
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = module.eks_vpc.vpc.id
}

## Associate IGW with route table
resource "aws_route_table" "public_route_table" {
  vpc_id = module.eks_vpc.vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
}  

# Associate public route table with public subnets
resource "aws_route_table_association" "public_subnets_route_table" {
  count          = length(module.eks_public_subnets[*].subnet.id)
  subnet_id      = module.eks_public_subnets[count.index].subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
## END Public subnet Created

module "eks_pod_subnets" {
  source = "../../modules/subnet"
  count  = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.pod_cidr, 4, count.index)
  vpc_id            = module.eks_vpc.vpc.id
  name              = join("-", ["eks-pods", data.aws_availability_zones.available.names[count.index]])
  depends_on = [
    module.eks_vpc
  ]
}

module "eks_endpoint_subnet" {
  source = "../../modules/subnet"

  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = local.endpoint_subnet_range
  vpc_id            = module.eks_vpc.vpc.id
  name              = join("-", ["eks-endpoint", data.aws_availability_zones.available.names[0]])
  depends_on = [
    module.eks_vpc
  ]
}