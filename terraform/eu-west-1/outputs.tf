output "repository_url" {
  description ="The ECR repository URL where the container image should be pushed."
  value = module.ecr.repository_url
}

output "dns_name" {
  description ="The ELB FQDN to point your browser to."
  value = module.elb.dns_name
}

