variable "cidr_block" {
  description = "The VPC CIDR block."
  nullable    = false
  default     = "10.112.1.0/24"
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/(16|24))$", var.cidr_block))
    error_message = "Must be a valid CIDR block (only /16 or /24 supported :))."
  }
}
