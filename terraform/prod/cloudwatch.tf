# アプリケーション本体のログ出力先
resource "aws_cloudwatch_log_group" "prod" {
  name              = "/ecs/${var.project}-${var.environment}-logs"
  retention_in_days = 7
}

# マイグレーションのログ出力先
resource "aws_cloudwatch_log_group" "prod_migration" {
  name              = "/ecs/${var.project}-${var.environment}-migration-logs"
  retention_in_days = 7
}

# -----------------------------------------------------------------------
# ALB 5xx Alarm (ユーザーへの5xxエラー返却を検知)
# 外部公開サービスの可用性低下を把握する。一次切り分けの起点となる重要監視。
# -----------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # データがない場合はアラームを発生させない（例：ALBにトラフィックがない時間帯など）

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# ECS CPU (コンテナのCPU逼迫を検知)
# レスポンス悪化や処理遅延、スケール不足の兆候を早期把握する。性能劣化によるサービス品質低下の予防に寄与する
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-ecs-cpu-high"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.ecs_cpu_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # データがない場合はアラームを発生させない（例：タスクが存在しない場合など）

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# ECS Memory (リソース枯渇による処理遅延を検知)
# メモリ不足によるレスポンス悪化や処理遅延の兆候を早期把握する。性能劣化によるサービス品質低下の予防に寄与する。
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project}-${var.environment}-ecs-memory-high"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.ecs_memory_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # データがない場合はアラームを発生させない（例：タスクが存在しない場合など）

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# ECS RunningTaskCount (稼働タスク数の減少を検知)
# タスクの異常停止やスケール不足の兆候を早期把握する。継続稼働確認の中心となる監視。
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_running_task_low" {
  alarm_name          = "${var.project}-${var.environment}-ecs-running-task-low"
  namespace           = "AWS/ECS"
  metric_name         = "RunningTaskCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 2
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching" # データがない場合はアラームを発生させる（例：タスクが存在しない場合など）

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# RDS CPU (DB負荷上昇を検知)
# クエリ遅延やアプリ全体のレスポンス低下、接続処理遅延の兆候を早期把握する。DB起因の性能劣化監視として有効。
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-rds-cpu-high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.rds_cpu_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # データがない場合はアラームを発生させない（例：DBインスタンスが存在しない場合など）

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# RDS FreeStorageSpace (DBストレージ枯渇を検知)
# ストレージ不足によるDB書き込み失敗やサービス影響の兆候を早期把握する。DB起因の可用性低下予防に寄与する。
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${var.project}-${var.environment}-rds-free-storage-low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.rds_free_storage_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching" # データがない場合はアラームを発生させない（例：DBインスタンスが存在しない場合など）

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# アプリケーションエラーログ（アプリ内部で発生する例外やエラーをメトリクス化して検知）
# ALBやECSメトリクスだけでは把握しづらい業務処理異常を早期発見する。
# ログにERRORやExceptionが含まれる行をカウントするフィルタを作成し、一定数以上発生した場合にアラームを発火させる。
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_metric_filter" "app_error_filter" {
  name           = "${var.project}-${var.environment}-app-error-filter"
  log_group_name = aws_cloudwatch_log_group.prod.name
  pattern        = "?ERROR ?Error ?Exception"

  metric_transformation {
    name      = "${var.project}-${var.environment}-app-error-count"
    namespace = "${var.project}/${var.environment}/logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_error_alarm" {
  alarm_name          = "${var.project}-${var.environment}-app-error-log"
  namespace           = "${var.project}/${var.environment}/logs"
  metric_name         = aws_cloudwatch_log_metric_filter.app_error_filter.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# ------------------------------------------------------------------------------------------
# CloudWatch Dashboard (サービスの健全性を示す主要メトリクスを単一画面で可視化)
# 障害発生時の初動対応と原因切り分けを迅速化する。監視結果の点ではなく面での把握に有効。
# ------------------------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.project}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        # オートスケーリングの挙動確認とリソースのサチュレーション（飽和）監視用
        # 障害発生時の影響範囲と深刻度の初動評価に有効。
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.ecs_service.name,
            "ClusterName", aws_ecs_cluster.ecs_cluster.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Resource Usage"
        }
      },

      {
        # ALBの5xxエラー数を表示することで、ユーザーへのエラー返却状況をリアルタイムで把握する。
        # 障害発生時の影響範囲と深刻度の初動評価に有効。
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer",
            aws_lb.alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB 5XX Errors"
        }
      },

      {
        # DB負荷とストレージ状況を一画面で把握することで、DB起因の性能劣化や可用性低下の兆候を早期発見する。
        # 障害発生時の影響範囲と深刻度の初動評価に有効。
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mysql.id],
            [".", "FreeStorageSpace", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Resource Usage & Storage"
        }
      },

      {
        # ECSの稼働タスク数を表示することで、タスクの異常停止やスケール不足の兆候をリアルタイムで把握する。
        # 障害発生時の影響範囲と深刻度の初動評価に有効。
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ServiceName", aws_ecs_service.ecs_service.name,
            "ClusterName", aws_ecs_cluster.ecs_cluster.name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Running Task Count"
        }
      }
    ]
  })
}
