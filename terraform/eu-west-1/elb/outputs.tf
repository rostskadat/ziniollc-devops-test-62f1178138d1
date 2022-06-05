output "target_group_arn" {
  description = "The Target Group ARN."
  value       = aws_lb_target_group.target_group.arn
}

output "dns_name" {
  description = "The DNS name of the ELB."
  value       = aws_lb.lb.dns_name
}
