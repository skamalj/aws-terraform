terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.36.1"
    }
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_fargate_provider" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      environment = var.environment
      portMappings = [
        {
          containerPort = var.port
        }
      ]
      secrets = var.secrets
      logConfiguration = {
                logDriver = "awslogs"
                options = {
                    awslogs-group =  var.log_group
                    awslogs-region =  "ap-south-1"
                    awslogs-create-group = "true"
                    awslogs-stream-prefix = var.name
                }
            }
    }])

  family = var.name
  cpu = var.cpu
  memory = var.memory
  network_mode = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
  }
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn
}

resource "aws_ecs_service" "ecs_service" {
    name = var.name
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.task_definition.arn
    desired_count = 1
    deployment_circuit_breaker {
      enable = true
      rollback = true
    }
    load_balancer {
        target_group_arn = var.target_group_arn
        container_name = var.name
        container_port = var.port     
    }
    network_configuration {
      subnets = var.subnets
      security_groups = var.security_groups
    }
    enable_ecs_managed_tags = true
    health_check_grace_period_seconds = 30
    launch_type = "FARGATE"
}