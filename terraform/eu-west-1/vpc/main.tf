#------------------------------------------------------------------------------
#
# This creates a simple VPC with some frontend subnets and some api 
# subnet where the ECS fargate cluster will be deployed. Please note that in
# a real production context this should not be part of the api 
# infrastructure but should be part of the organization landing zone, within
# the account provisioning process.
#
resource "aws_vpc" "workload" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-workload" }
}

# We then create the Internet Gateway in order to have access to internet
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.workload.id
  tags = {
    Name = "vpc-workload/internet-gateway"
  }
}

# I create an Elastic IP for each AZ.
resource "aws_eip" "nat_gateway_eip" {
  for_each = toset(data.aws_availability_zones.available.names)

  tags = {
    Name = "vpc-workload/${each.key}/nat-gateway-eip"
  }
}

# And then create a NAT gateway for each of them, and
# associating it with one EIP previously created
resource "aws_nat_gateway" "vpc_nat_gw" {
  for_each      = toset(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.nat_gateway_eip[each.key].id
  subnet_id     = aws_subnet.frontends[each.key].id
  tags = {
    Name = "vpc-workload/${each.key}/nat-gateway"
  }

  depends_on = [aws_internet_gateway.vpc_igw, aws_subnet.frontends]
}

# The frontend subnets will be used to deploy the load balancer
resource "aws_subnet" "frontends" {
  for_each          = local.frontend_subnets_cidrs
  vpc_id            = aws_vpc.workload.id
  cidr_block        = each.value.cidr
  availability_zone = each.key
  tags              = { Name = "frontend-${each.key}" }

  depends_on = [aws_internet_gateway.vpc_igw]
}

# I then create the routing table for the public subnet
resource "aws_route_table" "frontend_subnet_route_table" {
  for_each = local.frontend_subnets_cidrs
  vpc_id   = aws_vpc.workload.id
  route {
    # we send everything to the Internet gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
  tags = {
    Name = "vpc-workload/${each.key}/frontend-subnet-route-table"
  }
}

resource "aws_route_table_association" "frontend_subnet_route_table_association" {
  for_each       = local.frontend_subnets_cidrs
  route_table_id = aws_route_table.frontend_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.frontends[each.key].id
}

# And then the subnet for the api and db subnets
resource "aws_subnet" "apis" {
  for_each          = local.api_subnets_cidrs
  vpc_id            = aws_vpc.workload.id
  cidr_block        = each.value.cidr
  availability_zone = each.key
  tags              = { Name = "api-${each.key}" }
}

resource "aws_subnet" "dbs" {
  for_each          = local.db_subnets_cidrs
  vpc_id            = aws_vpc.workload.id
  cidr_block        = each.value.cidr
  availability_zone = each.key
  tags              = { Name = "db-${each.key}" }
}


resource "aws_route_table" "private_subnet_route_table" {
  for_each = local.api_subnets_cidrs
  vpc_id   = aws_vpc.workload.id
  tags = {
    Name = "vpc-workload/${each.key}/private-subnet-route-table"
  }
}

resource "aws_route" "nat_r" {
  for_each               = local.api_subnets_cidrs
  route_table_id         = aws_route_table.private_subnet_route_table[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_nat_gw[each.key].id
  depends_on             = [aws_route_table.private_subnet_route_table]
}

resource "aws_route_table_association" "api_subnet_route_table_association" {
  for_each       = local.api_subnets_cidrs
  route_table_id = aws_route_table.private_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.apis[each.key].id
}

resource "aws_route_table_association" "db_subnet_route_table_association" {
  for_each       = local.db_subnets_cidrs
  route_table_id = aws_route_table.private_subnet_route_table[each.key].id
  subnet_id      = aws_subnet.dbs[each.key].id
}

