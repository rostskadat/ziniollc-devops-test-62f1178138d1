#------------------------------------------------------------------------------
#
# This creates a simple VPC with some frontend subnets and some api 
# subnet where the ECS fargate cluster will be deployed. Please note that in
# a real production context this should not be part of the api 
# infrastructure but should be part of the organization landing zone, within
# the account provisioning process.
#
resource "aws_db_subnet_group" "default" {
  name        = "main"
  description = "The subnet where the DB is deployed."
  subnet_ids  = var.db_subnet_ids
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  copy_tags_to_snapshot  = true
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.default.name
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  port                   = var.port
  username               = var.username
  password               = var.password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = var.vpc_security_group_ids
}
