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
    container_port          = var.api_port
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
    target_group_arn = var.api_target_group_arn
    container_name   = "api"
    container_port   = var.api_port
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = var.api_security_groups
    subnets          = var.api_subnet_ids
  }
}
