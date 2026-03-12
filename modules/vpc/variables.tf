variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpcs_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
