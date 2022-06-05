output "cluster_id" {
  description = "ARN that identifies the cluster."
  value       = aws_ecs_cluster.cluster.id
}

