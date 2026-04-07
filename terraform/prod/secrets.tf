#-----------------------------
# Secrets Manager
#-----------------------------
resource "aws_secretsmanager_secret" "app_key" {
  name                    = "${var.project}/${var.environment}/app_key"
  recovery_window_in_days = 7

  tags = {
    Name    = "${var.project}-${var.environment}-app-key"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app_key" {
  secret_id     = aws_secretsmanager_secret.app_key.id
  secret_string = var.app_key
}
