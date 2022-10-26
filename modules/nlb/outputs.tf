output "nlb" {
  value = aws_lb.nlb
  description = "AWS ELB object (NLB)"
}
output "target_group" {
  value = aws_lb_target_group.target_group
}
output "nlb_metric_suffix" {
  value = aws_lb.nlb.arn_suffix
}