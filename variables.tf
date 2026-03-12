variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "vpcs_azs" {
  description = "Availability Zones to be used"
  type        = list(string)
}

variable "alert_email" {
  description = "The email address for CloudWatch alerts"
  type        = string
}
