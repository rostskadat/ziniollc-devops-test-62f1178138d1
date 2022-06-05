#------------------------------------------------------------------------------
#
# We create an ELB to access the container in the ECS cluster.
#
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
    log_prefix               = "lb/access-logs"
    elb_account_id           = 156460612806
    aws_account_id           = data.aws_caller_identity.current.account_id
  })
}

resource "aws_lb" "lb" {
  name_prefix        = "zinio"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.lb_security_groups
  subnets            = var.frontend_subnet_ids

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "lb/access-logs"
    enabled = true
  }

}

resource "aws_lb_target_group" "target_group" {
  name_prefix          = "zinio"
  port                 = var.api_port
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
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
