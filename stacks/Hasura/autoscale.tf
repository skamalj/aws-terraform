resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.name}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [
    module.hasura_service
  ]
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "hasura-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value     = 1
    disable_scale_in = false
    customized_metric_specification {
      metric_name = "ActiveFlowCount"
      namespace   = "AWS/NetworkELB"
      statistic   = "Average"

      dimensions {
        name  = "LoadBalancer"
        value = module.nlb.nlb_metric_suffix
      }
    }
  }
}
