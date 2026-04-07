#-----------------------------
# RDS parameter group
#-----------------------------
resource "aws_db_parameter_group" "mysql_parametergroup" {
  name   = "${var.project}-${var.environment}-mysql-parametergroup"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-parametergroup"
    Project = var.project
    Env     = var.environment
  }
}

#-----------------------------
# RDS option group
#-----------------------------
resource "aws_db_option_group" "mysql_optiongroup" {
  name                 = "${var.project}-${var.environment}-mysql-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-optiongroup"
    Project = var.project
    Env     = var.environment
  }
}

#-----------------------------
# RDS instance
#-----------------------------
resource "aws_db_instance" "mysql" {
  identifier            = "${var.project}-${var.environment}-mysql"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true
  engine                = "mysql"
  engine_version        = "8.0.40"
  instance_class        = "db.t3.small"

  username = "laravel"
  # RDSに Secrets Manager 管理を任せる。RDSは master_user_secret を持つようになる。
  manage_master_user_password = true

  multi_az = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  port                   = 3306

  db_name              = "laravel_nagoyameshi"
  parameter_group_name = aws_db_parameter_group.mysql_parametergroup.name
  option_group_name    = aws_db_option_group.mysql_optiongroup.name

  backup_window              = "04:00-05:00"
  backup_retention_period    = 7
  maintenance_window         = "Mon:05:00-Mon:08:00"
  auto_minor_version_upgrade = false

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project}-${var.environment}-mysql-final-snapshot"

  apply_immediately = false

  tags = {
    Name    = "${var.project}-${var.environment}-mysql"
    Project = var.project
    Env     = var.environment
  }
}
