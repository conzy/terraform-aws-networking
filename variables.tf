variable "high_availability" {
  type        = bool
  default     = false
  description = "If this is a production environment and high availability is required this should be enabled."
}

variable "base_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
