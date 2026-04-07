# ---------------------------------------------
# Security Group
# ---------------------------------------------

# ---------------------------------------------
# ALB security group
# ---------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB security group"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-alb-sg"
    Project = var.project
    Env     = var.environment
  }
}

# インバウンド: CloudFrontからのHTTPSのみ許可
resource "aws_security_group_rule" "alb_ingress_https_from_cloudfront" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

# インバウンド: ALBに対して会社のグローバルIPからの通信も許可（検証時必要に応じて追加）
/*
resource "aws_security_group_rule" "alb_ingress_https_from_office" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.allowed_ip_cidrs # variables.tfにある変数を使用
}
*/

# アウトバウンド: ECSへのポート80(Apache)のみ許可
resource "aws_security_group_rule" "alb_egress_http_to_ecs" {
  security_group_id        = aws_security_group.alb_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.ecs_sg.id
}

# ---------------------------------------------
# ECS security group
# ---------------------------------------------
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "ECS Fargate security group"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-ecs-sg"
    Project = var.project
    Env     = var.environment
  }
}

# インバウンド: ALBからのポート80(Apache)のみ許可
resource "aws_security_group_rule" "ecs_ingress_http_from_alb" {
  security_group_id        = aws_security_group.ecs_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alb_sg.id
}

# アウトバウンド: 全許可（ECRからのプルやRDSへの接続に必要）
resource "aws_security_group_rule" "ecs_egress_all" {
  security_group_id = aws_security_group.ecs_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# ---------------------------------------------
# RDS security group
# ---------------------------------------------
resource "aws_security_group" "db_sg" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-db-sg"
    Project = var.project
    Env     = var.environment
  }
}

# インバウンド: ECSからのポート3306(MySQL)のみ許可
resource "aws_security_group_rule" "db_ingress_mysql_from_ecs" {
  security_group_id        = aws_security_group.db_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.ecs_sg.id
}

# ---------------------------------------------
# CodeBuild security group
# ---------------------------------------------
resource "aws_security_group" "codebuild_sg" {
  name        = "${var.project}-${var.environment}-codebuild-sg"
  description = "CodeBuild security group"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-codebuild-sg"
    Project = var.project
    Env     = var.environment
  }
}

# アウトバウンド: 全許可（CodeBuildがECRからイメージをプルするために必要）
resource "aws_security_group_rule" "codebuild_egress_all" {
  security_group_id = aws_security_group.codebuild_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
