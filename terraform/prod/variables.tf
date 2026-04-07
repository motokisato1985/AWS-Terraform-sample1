# ---------------------------------------------
# Variables
# ---------------------------------------------

variable "project" {
  type = string
}

variable "environment" {
  type        = string
  description = "環境名 (dev, prod)"
}

variable "aws_region" {
  type = string
}

variable "alb_https_port" {
  type        = number
  description = "ALB HTTPS listener port"
  default     = 443
}

variable "alb_ssl_policy" {
  type        = string
  description = "ALB SSL policy"
  default     = "ELBSecurityPolicy-2016-08"
}

variable "alb_target_group_port" {
  type        = number
  description = "ALB target group port"
  default     = 80
}

variable "alb_health_check_path" {
  type        = string
  description = "ALB target group health check path"
  default     = "/"
}

variable "alb_health_check_matcher" {
  type        = string
  description = "ALB target group health check success codes"
  default     = "200"
}

variable "alb_health_check_healthy_threshold" {
  type        = number
  description = "Healthy threshold count for ALB target group health check"
  default     = 3
}

variable "alb_health_check_unhealthy_threshold" {
  type        = number
  description = "Unhealthy threshold count for ALB target group health check"
  default     = 2
}

variable "alb_health_check_timeout" {
  type        = number
  description = "Timeout seconds for ALB target group health check"
  default     = 5
}

variable "alb_health_check_interval" {
  type        = number
  description = "Interval seconds for ALB target group health check"
  default     = 30
}

variable "cf_price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_200"
}

variable "cf_origin_http_port" {
  type        = number
  description = "CloudFront custom origin HTTP port"
  default     = 80
}

variable "cf_origin_https_port" {
  type        = number
  description = "CloudFront custom origin HTTPS port"
  default     = 443
}

variable "db_subnet_group_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "app_key" {
  description = "Laravel APP_KEY"
  type        = string
  sensitive   = true
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the application"
  type        = string
}

variable "alarm_email" {
  description = "Email address for SNS alarm notifications"
  type        = string
}

variable "ecs_cpu_threshold" {
  description = "Threshold for ECS CPU usage alarm"
  type        = number
  default     = 70
}

variable "ecs_memory_threshold" {
  description = "Threshold for ECS memory usage alarm"
  type        = number
  default     = 70
}

variable "rds_cpu_threshold" {
  description = "Threshold for RDS CPU usage alarm"
  type        = number
  default     = 70
}

variable "rds_free_storage_threshold" {
  description = "Threshold for RDS free storage (bytes)"
  type        = number
  default     = 5368709120 # 5GB
}

variable "codestar_connection_arn" {
  type        = string
  description = "CodeStar ConnectionsのARN"
}
