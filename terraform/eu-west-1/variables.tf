variable "mysql_dbname" {
  description = "The name of the db."
  default     = "db"
  type        = string
}

variable "mysql_port" {
  description = "The port on which the DB accepts connections."
  default     = 3306
  type        = number
}

variable "mysql_username" {
  description = "The application username to access the db."
  default     = "user"
  type        = string
}

variable "mysql_password" {
  description = "The mysql password to access the db."
  default     = "password"
  type        = string
  sensitive   = true
}
