output "vpc_id" {
  description = "The ID of the newly created VPC."
  value       = aws_vpc.workload.id
}

output "frontend_subnets" {
  description = "The list of frontend subnets."
  value       = aws_subnet.frontends
}

output "api_subnets" {
  description = "The list of api subnets."
  value       = aws_subnet.apis
}

output "db_subnets" {
  description = "The list of db subnets."
  value       = aws_subnet.dbs
}
