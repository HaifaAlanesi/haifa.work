
resource "aws_db_subnet_group" "main" {
  name       = "haifa-db-group"
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  db_name              = "haifadb"
  username             = "admin"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az             = true
  skip_final_snapshot  = true
}

resource "aws_security_group" "db_sg" {
  name   = "haifa-db-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups=[var.web_sg_id]
   }
   # The "Outbound" rule (Allow the DB to talk back to the internet if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
