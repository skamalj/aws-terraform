output "lb" {
  value = aws_lb.alb
  description = "AWS ELB object (NLB)"
}
output "target_group" {
  value = aws_lb_target_group.target_group
}
output "lb_metric_suffix" {
  value = aws_lb.alb.arn_suffix
}