
# 1. The "Recipe" (Launch Template)
# This tells AWS exactly how to build each new server
resource "aws_launch_template" "web" {
  name_prefix   = "haifa-web-template-"
  image_id      = "ami-0c101f26f147fa7fd" # Amazon Linux 2023
  instance_type = "t2.micro"

  # Security Group for the Servers
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # The Health Check & Database Connection Script
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd php php-mysqlnd mariadb105
              systemctl start httpd
              systemctl enable httpd

              # Create the dynamic health check page
              cat <<VPC_EOF > /var/www/html/index.php
              <?php
              \$host = "${var.db_endpoint}";
              \$user = "admin";
              \$pass = "${var.db_password}";
              echo "<h1>Welcome to Haifa.work</h1>";
              \$conn = new mysqli(\$host, \$user, \$pass);
              if (\$conn->connect_error) {
                  echo "<p style='color:red;'>Database Connection: FAILED</p>";
              } else {
                  echo "<p style='color:green;'>Database Connection: SUCCESSFUL</p>";
              }
              ?>
              VPC_EOF
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 2. The "Manager" (Auto Scaling Group)
# This ensures we always have 2 servers running for High Availability
resource "aws_autoscaling_group" "web_asg" {
  name                = "haifa-asg"
  vpc_zone_identifier = var.public_subnets
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Connects the ASG to the Load Balancer
  target_group_arns = [aws_lb_target_group.web_tg.arn]

  # Use ELB (Load Balancer) to decide if a server is "dead"
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "haifa-asg-worker"
    propagate_at_launch = true
  }
}

# 3. The "Traffic Cop" (Application Load Balancer)
resource "aws_lb" "web_alb" {
  name               = "haifa-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
}

# 4. The "Waiting Room" (Target Group)
resource "aws_lb_target_group" "web_tg" {
  name     = "haifa-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/index.php"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 5. The "Front Door" (Listener)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 6. Security Group for the Load Balancer (Public)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}
# Security Group for the Web Servers (Private to ALB)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    # This is the "Magic Link" - only allows the Web SG to talk to the DB
    security_groups = [aws_security_group.alb_sg.id]
  }

  # The "Outbound" rule (Allow the DB to talk back to the internet if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

# 8. The Notification Channel (SNS)
resource "aws_sns_topic" "alerts" {
  name = "haifa-work-alerts"
}

# 9. Your Email Subscription
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint = var.alert_email # <--- Change this to your actual email!
}

# 10. The CloudWatch Alarm
# This watches the Load Balancer to see if your ASG workers are failing health checks
resource "aws_cloudwatch_metric_alarm" "asg_health_alarm" {
  alarm_name          = "haifa-asg-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert: One or more servers in the Haifa.work ASG have failed health checks."
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.web_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
  }
}

