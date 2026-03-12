
output "web_sg_id" { value = aws_security_group.web_sg.id }
output "alb_dns"   { value = aws_lb.web_alb.dns_name }
