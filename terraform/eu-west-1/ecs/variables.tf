variable "api_desired_count" {
  description = "The number of desired API Microservice count."
  nullable    = true
  default     = 1
  type        = number
  validation {
    condition     = can(var.api_desired_count > 0)
    error_message = "Must be a number greater than 0."
  }
}

variable "api_subnet_ids" {
  description = "The list of api subnets ids where the api service will be located."
  nullable    = false
  type        = list(string)
}

variable "api_security_groups" {
  description = "A list of security group IDs to assign to the API service."
  nullable    = false
  type        = list(string)
}

variable "api_repository_url" {
  description = "The URL of the ECR repository for API container."
  nullable    = false
  type        = string
}

variable "api_port" {
  description = "The port of the api container."
  nullable    = false
  type        = number
}

variable "api_target_group_arn" {
  description = "The ARN of the Target Group where container will be registered."
  nullable    = false
  type        = string
}

variable "mysql_host" {
  description = "ThThe hostname of the RDS instance."
  nullable    = false
  type        = string
}

variable "mysql_port" {
  description = "The port on which the DB accepts connections."
  nullable    = false
  type        = number
}

variable "mysql_dbname" {
  description = "The name of the db."
  nullable    = false
  type        = string
}

variable "mysql_username" {
  description = "The application username to access the db."
  nullable    = false
  type        = string
}


variable "mysql_password_arn" {
  description = "The ARN of the SecretManager Secret that contains the MYSQL password."
  nullable    = false
  type        = string
}

variable "mysql_root_password_arn" {
  description = "The ARN of the SecretManager Secret that contains the MYSQL password."
  nullable    = false
  type        = string
}

