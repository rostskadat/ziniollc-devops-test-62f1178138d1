output "cluster_id" {
  description = "ARN that identifies the cluster."
  value       = aws_ecs_cluster.cluster.id
}

output "dns_name" {
  description = "The DNS name of the ELB."
  value       = aws_lb.api_lb.dns_name
}


