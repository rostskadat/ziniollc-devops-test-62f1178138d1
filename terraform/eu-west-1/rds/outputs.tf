output "address" {
  description = "The hostname of the RDS instance."
  value       = aws_db_instance.default.address
}

output "db_name" {
  description = "The name of the db."
  value       = aws_db_instance.default.db_name
}

output "port" {
  description = "The port on which the DB accepts connections."
  value       = aws_db_instance.default.port
}

output "username" {
  description = "The application username to access the db."
  value       = aws_db_instance.default.username
}
