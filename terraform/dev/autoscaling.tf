# ---------------------------------------------
# ECS Service Auto Scaling Target
# ---------------------------------------------
resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = 1
  max_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ---------------------------------------------
# ECS Service Auto Scaling Policy (CPU)
# ---------------------------------------------
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "${var.project}-${var.environment}-ecs-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    # サービス継続性を考慮し、スパイク耐性を持たせるため70%を閾値に設定
    target_value = 70

    # 頻繁なスケーリングによるフラッピング（増減の繰り返し）を防ぐための待機時間設定
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
  }
}
