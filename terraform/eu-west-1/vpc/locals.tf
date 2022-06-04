locals {

  # These map allow to simply create the CIDR blocks for the different
  # subnets. There are many ways to actually do that. Another more succint
  # way might use https://www.terraform.io/language/functions/cidrsubnets
  frontend_subnets_cidrs = {
    "${data.aws_availability_zones.available.names[0]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 0),
    },
    "${data.aws_availability_zones.available.names[1]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 1),
    },
    "${data.aws_availability_zones.available.names[2]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 2),
    }
  }
  api_subnets_cidrs = {
    "${data.aws_availability_zones.available.names[0]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 3),
    },
    "${data.aws_availability_zones.available.names[1]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 4),
    },
    "${data.aws_availability_zones.available.names[2]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 5)
    }
  }
  db_subnets_cidrs = {
    "${data.aws_availability_zones.available.names[0]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 6),
    },
    "${data.aws_availability_zones.available.names[1]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 7),
    },
    "${data.aws_availability_zones.available.names[2]}" = {
      cidr = cidrsubnet(var.cidr_block, 4, 8)
    }
  }
}

