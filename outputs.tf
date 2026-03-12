# The "Front Door" (Global URL with HTTPS)
output "website_url_cloudfront" {
  description = "The global CDN address for haifa.work"
  value       = module.cdn.cloudfront_domain_name
}

# The "Back Door" (Internal Load Balancer URL)
output "alb_dns_name" {
  description = "The direct DNS name of the Load Balancer"
  value       = module.web_server.alb_dns
}

# The Database connection string
output "database_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = module.database.db_endpoint
}
