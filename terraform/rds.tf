resource "aws_db_subnet_group" "rds" {
  name       = "finops-rds-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "rds" {
  identifier        = "finops-postgres"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = var.db_user
  password          = var.db_password
  db_name           = var.db_name
  db_subnet_group_name = aws_db_subnet_group.rds.name
  skip_final_snapshot   = true
  publicly_accessible   = false

  tags = {
    Name = "FinOps-DB"
  }
}
