output "rds_address" {
  value = module.rds.address
}

output "repository_url" {
  value = module.ecr.repository_url
}

output "dns_name" {
  value = module.ecs.dns_name
}

