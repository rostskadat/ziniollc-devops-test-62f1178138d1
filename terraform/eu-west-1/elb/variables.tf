variable "vpc_id" {
  description = "The VPC where the API Microservice is to be deployed."
  nullable    = false
  type        = string
  validation {
    condition     = can(regex("^vpc-[0-9a-z]{17}$", var.vpc_id))
    error_message = "Must be a valid VPC ID."
  }
}

variable "frontend_subnet_ids" {
  description = "The list of frontend subnets ids where the load balancer will be located."
  nullable    = false
  type        = list(string)
}

variable "lb_security_groups" {
  description = "A list of security group IDs to assign to the LB."
  nullable    = false
  type        = list(string)
}

variable "api_port" {
  description = "The port of the api container."
  nullable    = false
  type        = number
}

