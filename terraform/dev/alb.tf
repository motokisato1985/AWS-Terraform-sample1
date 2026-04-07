#-----------------------------
# Application Load Balancer
#-----------------------------

resource "aws_lb" "alb" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets = [
    data.aws_subnet.public_subnet_1a.id,
    data.aws_subnet.public_subnet_1c.id
  ]
  tags = {
    Name    = "${var.project}-${var.environment}-alb"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_lb_listener" "alb_listener_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_https_port
  protocol          = "HTTPS"

  ssl_policy      = var.alb_ssl_policy
  certificate_arn = aws_acm_certificate.tokyo_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

#-----------------------------
# Target Group
#-----------------------------
resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.project}-${var.environment}-tg-ecs"
  vpc_id      = data.aws_vpc.vpc.id
  port        = var.alb_target_group_port
  protocol    = "HTTP" # ALBからコンテナへはHTTPで通信
  target_type = "ip"   # FargateはIPアドレスでターゲット指定

  tags = {
    Name    = "${var.project}-${var.environment}-tg-ecs"
    Project = var.project
    Env     = var.environment
  }

  health_check {
    path                = var.alb_health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = var.alb_health_check_healthy_threshold
    unhealthy_threshold = var.alb_health_check_unhealthy_threshold
    timeout             = var.alb_health_check_timeout
    interval            = var.alb_health_check_interval
    matcher             = var.alb_health_check_matcher
  }
}
