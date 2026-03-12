# 1. Build the Network
module "network" {
  source   = "./modules/vpc"
  vpcs_azs = ["us-east-1a", "us-east-1b"]
}

# 2. Build the Web Servers (THIS IS THE CODE YOU ASKED ABOUT)
module "web_server" {
  source         = "./modules/ec2"
  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets
  db_endpoint    = module.database.db_endpoint
  db_password    = var.db_password
  # Add this line below to fix the error:
  alert_email = var.alert_email
}

# 3. Build the Database
module "database" {
  source             = "./modules/rds"
  vpc_id             = module.network.vpc_id
  private_subnets    = module.network.private_subnets
  web_sg_id          = module.web_server.web_sg_id
  db_password        = var.db_password
}

module "cdn" {
  source       = "./modules/cloudfront"
  alb_dns_name = module.web_server.alb_dns
}
