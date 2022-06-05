# We first create a simple VPC with frontend and application subnet.
module "vpc" {
  source = "./vpc"
}

# we then create the ECR repository where the docker image will be stored.
# It could be argued that should be created during the bootstrap process.
module "ecr" {
  source = "./ecr"
}

resource "aws_secretsmanager_secret" "mysql_password" {
  name_prefix = "ziniollc-devops-test-62f1178138d1/mysql_password"
  description = "The mysql password for the application user"
}

resource "aws_secretsmanager_secret_version" "mysql_password_latest" {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = var.mysql_password
}

resource "aws_secretsmanager_secret" "mysql_root_password" {
  name_prefix = "ziniollc-devops-test-62f1178138d1/mysql_root_password"
  description = "The root mysql password"
}

resource "aws_secretsmanager_secret_version" "mysql_root_password_latest" {
  secret_id     = aws_secretsmanager_secret.mysql_root_password.id
  secret_string = var.mysql_password
}

resource "aws_security_group" "lb_security_group" {
  name        = "allow_lb_traffic"
  description = "Allow ELB traffic"
  vpc_id      = module.vpc.vpc_id

  # when we have a domain name and a hosted zone, we can create an ACM certificate
  # and use HTTPS
  ingress {
    description      = "HTTP traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_lb_traffic"
  }
}

resource "aws_security_group" "api_security_group" {
  name        = "allow_elb_2_api"
  description = "Allow ELB to access API Microservice"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Swoole traffic"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = flatten([
      for az, subnet in module.vpc.frontend_subnets : [
        subnet.cidr_block
      ]
    ])
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_elb_2_api"
  }
}

resource "aws_security_group" "db_security_group" {
  name        = "allow_api_2_mysql"
  description = "Allow API Microservice to access MySQL DB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL traffic"
    from_port       = var.mysql_port
    to_port         = var.mysql_port
    protocol        = "tcp"
    security_groups = [aws_security_group.api_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_api_2_mysql"
  }
}

module "rds" {
  source = "./rds"

  port     = var.mysql_port
  db_name  = var.mysql_dbname
  username = var.mysql_username
  password = var.mysql_password
  db_subnet_ids = flatten([
    for az, subnet in module.vpc.db_subnets : [
      subnet.id
    ]
  ])
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

# Then I create an ELB to be able to access the microservice.
module "elb" {
  source = "./elb"

  vpc_id = module.vpc.vpc_id
  frontend_subnet_ids = flatten([
    for az, subnet in module.vpc.frontend_subnets : [
      subnet.id
    ]
  ])
  lb_security_groups = [aws_security_group.lb_security_group.id]
  api_port           = var.api_port
}


# we then create the ECS cluster (with Fargate provider) where the 
# containers will be executed
module "ecs" {
  source = "./ecs"

  api_subnet_ids = flatten([
    for az, subnet in module.vpc.api_subnets : [
      subnet.id
    ]
  ])
  api_security_groups  = [aws_security_group.api_security_group.id]
  api_repository_url   = module.ecr.repository_url
  api_port             = var.api_port
  api_target_group_arn = module.elb.target_group_arn
  # NOTE: we always use the resource attributes and not the variables
  mysql_host              = module.rds.address
  mysql_port              = module.rds.port
  mysql_dbname            = module.rds.db_name
  mysql_username          = module.rds.username
  mysql_password_arn      = aws_secretsmanager_secret.mysql_password.id
  mysql_root_password_arn = aws_secretsmanager_secret.mysql_password.arn

  depends_on = [module.rds, module.elb]
}
