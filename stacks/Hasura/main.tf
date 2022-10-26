terraform {
  backend "s3" {
    key    = "devtest/tf/hasura"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.12.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = var.name
}

module "task_execution_role" {
  source = "../../modules/iam_role"
  name = "AmazonECSTaskExecutionRole"
  policies = ["AmazonECSTaskExecutionRolePolicy"]
  assume_role_policy = file("task_execution_assume_role_policy.json")
}

module "hasura_service" {
  source  = "../../modules/ecs"
  name    = var.name
  image = "715267777840.dkr.ecr.ap-south-1.amazonaws.com/hasura/graphql-engine:v2.13.0"
  port = var.port
  execution_role_arn  = module.task_execution_role.role.arn
  target_group_arn = module.nlb.target_group.arn
  subnets = module.ecs_subnets[*].subnet.id
  security_groups = [aws_security_group.ecs_sg.id]
  aws_region = data.aws_region.current
  log_group = aws_cloudwatch_log_group.log_group.name
  environment = local.hasura_env
}
