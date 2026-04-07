#-----------------------------
# SSM Parameter Store
#-----------------------------

resource "aws_ssm_parameter" "host" {
  name  = "/${var.project}/${var.environment}/DB_HOST"
  type  = "String"
  value = aws_db_instance.mysql.address
}

resource "aws_ssm_parameter" "port" {
  name  = "/${var.project}/${var.environment}/DB_PORT"
  type  = "String"
  value = aws_db_instance.mysql.port
}

resource "aws_ssm_parameter" "database" {
  name  = "/${var.project}/${var.environment}/DB_DATABASE"
  type  = "String"
  value = aws_db_instance.mysql.db_name
}

