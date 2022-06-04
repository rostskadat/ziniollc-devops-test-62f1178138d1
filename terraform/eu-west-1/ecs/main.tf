#------------------------------------------------------------------------------
#
# This creates the ECS cluster where the microservice will be executed
#
# first let's encrypt the logs at rest
resource "aws_kms_key" "ecs_log_kms_key" {
  description             = "This key is used to encrypt the logs ECS container send to Cloudwatch Logs"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "ziniollc-devops-test-62f1178138d1/ecs"
}

resource "aws_ecs_cluster" "cluster" {
  name = "ziniollc-devops-test-62f1178138d1"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs_log_kms_key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_log_group.name
      }
    }
  }
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "Allow access to the SecretManager Secrets (such as MySQL Password and Root Password)"
  policy = templatefile("${path.module}/iam/ecs_task_execution_policy.json", {
    secret_arns = [var.mysql_password_arn, var.mysql_root_password_arn]
  })
}

resource "aws_iam_role" "api_execution_role" {
  name_prefix        = "api_execution_role"
  assume_role_policy = templatefile("${path.module}/iam/ecs_task_trust_policy.json", {})
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.ecs_task_execution_policy.arn
  ]
}

# Ref: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#family 
resource "aws_ecs_task_definition" "api_task_definition" {
  family                   = "api_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  # Ref: https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html
  container_definitions = templatefile("${path.module}/task-definitions/api.json", {
    image                   = "${var.api_repository_url}:latest"
    mysql_host              = var.mysql_host,
    mysql_port              = var.mysql_port,
    mysql_dbname            = var.mysql_dbname,
    mysql_user              = var.mysql_username,
    mysql_password_arn      = var.mysql_password_arn,
    mysql_root_password_arn = var.mysql_root_password_arn
    container_port          = var.container_port
    aws_region              = data.aws_region.current.name
    aws_log_group           = aws_cloudwatch_log_group.ecs_log_group.name
  })
  execution_role_arn = aws_iam_role.api_execution_role.arn
}

resource "aws_ecs_service" "api_service" {
  name                 = "api_service"
  cluster              = aws_ecs_cluster.cluster.id
  launch_type          = "FARGATE"
  task_definition      = aws_ecs_task_definition.api_task_definition.arn
  desired_count        = var.api_desired_count
  force_new_deployment = true

  load_balancer {
    target_group_arn = aws_lb_target_group.api_target_group.arn
    container_name   = "api"
    container_port   = var.container_port
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = var.api_security_groups
    subnets          = var.api_subnet_ids
  }
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "ziniollc-devops-test-62f1178138d1-lb-logs"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ref: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
resource "aws_s3_bucket_policy" "allow_log_delivery" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = templatefile("${path.module}/iam/lb_acess_logs_bucket_policy.json", {
    lb_acess_logs_bucket_arn = aws_s3_bucket.lb_logs.arn
    log_prefix               = "api_lb/access-logs"
    elb_account_id           = 156460612806
    aws_account_id           = data.aws_caller_identity.current.account_id
  })
}

resource "aws_lb" "api_lb" {
  name_prefix        = "zinio"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.lb_security_groups
  subnets            = var.frontend_subnet_ids

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "api_lb/access-logs"
    enabled = true
  }

}

resource "aws_lb_target_group" "api_target_group" {
  name_prefix          = "zinio"
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled = true
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.api_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }
}