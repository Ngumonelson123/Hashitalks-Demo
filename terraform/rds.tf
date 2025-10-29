resource "aws_db_subnet_group" "rds" {
  name       = "finops-rds-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "rds" {
  identifier             = "finops-postgres"
  engine                 = "postgres"
  # engine_version will use default supported version
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_user
  password               = var.db_password
  db_name                = var.db_name
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  backup_retention_period = 1
  storage_encrypted      = true

  tags = {
    Name        = "FinOps-DB"
    Environment = "demo"
    Project     = "FinOps-Kit"
  }
}
