
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "db_endpoint" { type = string }
variable "db_password" { type = string }
variable "alert_email" { type = string }
