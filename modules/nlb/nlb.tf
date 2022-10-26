terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.36.1"
    }
  }
}

resource "aws_lb" "nlb" {
  name               = var.name
  internal           = var.is_internal
  load_balancer_type = "network"
  subnets            =  var.subnets
  dynamic "access_logs" {
    for_each = var.access_logs_bucket == null ? [] : [var.access_logs_bucket]
    content {
        enabled = true
        bucket = access_logs.value 
    }
  }
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
}

resource "aws_lb_target_group" "target_group" {
  name        = var.name
  port        = var.port
  protocol    = var.protocol
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    enabled = true
    port = var.port
    protocol = var.protocol
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.listen_port
  protocol          = var.protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}