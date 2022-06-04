variable "port" {
  description = "The port on which the DB accepts connections."
  nullable    = false
  type        = number
}

variable "db_name" {
  description = "The name of the db."
  nullable    = false
  type        = string
}

variable "username" {
  description = "The application username to access the db."
  nullable    = false
  type        = string
}

variable "password" {
  description = "The application password to access the db."
  nullable    = false
  type        = string
  sensitive   = true
}

variable "db_subnet_ids" {
  description = "The list of db subnets where the DB service should be deployed"
  nullable    = false
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "The list of security group ids to associate with the DB"
  nullable    = false
  type        = list(string)
}

