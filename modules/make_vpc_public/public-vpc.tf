resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "vpc-igw"
  }
}

# Get availability zones for subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_eip" "nat_ip" {
  vpc = true
}


# Create NAT Gateway in public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = var.public_subnets[0].id
}

# Associate IGW with route table
resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
}  

# Associate public route table with public subnets
resource "aws_route_table_association" "public_subnets_route_table" {
  for_each =   zipmap(range(length(var.public_subnets)), var.public_subnets)
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

