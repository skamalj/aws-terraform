terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.12.1"
    }
  }
}

data "aws_iam_policy" "policy" {
  for_each = toset(var.policies)
  name = each.value
}

resource "aws_iam_role" "iam_role" {
  assume_role_policy = var.assume_role_policy
  name = var.name
  permissions_boundary = var.permissions_boundary
  tags = var.tags
}

# Attached secondary IP ranges for master
resource "aws_iam_role_policy_attachment" "policy_atatch" {
  for_each   = data.aws_iam_policy.policy
  role       = aws_iam_role.iam_role.name
  policy_arn = each.value.arn
}