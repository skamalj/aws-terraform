output "lb_dns" {
    value = module.nlb.lb.dns_name
}

output "lb_dns_int" {
    value = module.nlb-int.lb.dns_name
}