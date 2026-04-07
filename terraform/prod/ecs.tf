# ---------------------------------------------
# ECS Cluster
# ---------------------------------------------
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project}-${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # リソース監視を有効化
  }

  tags = {
    Name    = "${var.project}-${var.environment}-ecs-cluster"
    Project = var.project
    Env     = var.environment
  }
}

# キャパシティプロバイダー（Fargate）の関連付け
resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ---------------------------------------------------
# ECS Task Definition
# ---------------------------------------------------
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "${var.project}-${var.environment}-task-def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "2048" # 2 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-${var.environment}-container"
      image     = "${var.ecr_repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      # --- 環境変数 (機密情報以外) ---
      environment = [
        { name = "APP_ENV", value = "production" },
        { name = "APP_URL", value = "https://${var.domain}" }, # APEXドメイン
        { name = "FILESYSTEM_DISK", value = "public" },        # ストレージ設定
        { name = "DB_CONNECTION", value = "mysql" },
        { name = "DB_USERNAME", value = "laravel" }
      ]

      # 環境変数をParameter Storeから取得(APP、DB側の認証情報と合わせるため)
      secrets = [
        {
          name      = "APP_KEY"
          valueFrom = aws_secretsmanager_secret.app_key.arn
        },
        {
          name      = "DB_HOST"
          valueFrom = aws_ssm_parameter.host.arn
        },
        {
          name      = "DB_PORT"
          valueFrom = aws_ssm_parameter.port.arn
        },
        {
          name      = "DB_DATABASE"
          valueFrom = aws_ssm_parameter.database.arn
        },

        # RDSがSecrets Managerで管理するシークレットの password キーを参照
        { name = "DB_PASSWORD", valueFrom = "${aws_db_instance.mysql.master_user_secret[0].secret_arn}:password::" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prod.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  tags = {
    Name    = "${var.project}-${var.environment}-task-def"
    Project = var.project
    Env     = var.environment
  }
}

# ---------------------------------------------------
# ECS Migration Task Definition
# ---------------------------------------------------
resource "aws_ecs_task_definition" "ecs_migration_task" {
  family                   = "${var.project}-${var.environment}-migration-task-def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "1024" # 1 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project}-${var.environment}-container"
      image = "${var.ecr_repository_url}:latest"

      command = ["php", "artisan", "migrate", "--force"] # マイグレーションコマンド

      # --- 環境変数 (機密情報以外) ---
      environment = [
        { name = "APP_ENV", value = "production" },
        { name = "APP_URL", value = "https://${var.domain}" }, # APEXドメイン
        { name = "FILESYSTEM_DISK", value = "public" },        # ストレージ設定
        { name = "DB_CONNECTION", value = "mysql" },
        { name = "DB_USERNAME", value = "laravel" }
      ]

      # 環境変数をParameter Storeから取得(APP、DB側の認証情報と合わせるため)
      secrets = [
        {
          name      = "APP_KEY"
          valueFrom = aws_secretsmanager_secret.app_key.arn
        },
        {
          name      = "DB_HOST"
          valueFrom = aws_ssm_parameter.host.arn
        },
        {
          name      = "DB_PORT"
          valueFrom = aws_ssm_parameter.port.arn
        },
        {
          name      = "DB_DATABASE"
          valueFrom = aws_ssm_parameter.database.arn
        },

        # RDSがSecrets Managerで管理するシークレットの password キーを参照
        { name = "DB_PASSWORD", valueFrom = "${aws_db_instance.mysql.master_user_secret[0].secret_arn}:password::" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prod_migration.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  tags = {
    Name    = "${var.project}-${var.environment}-migration-task-def"
    Project = var.project
    Env     = var.environment
  }
}

# -------------------------------------------------------------------
# ECS Service
# -------------------------------------------------------------------

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.project}-${var.environment}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2 # 起動させるタスク数
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 50  # 最小稼働率
  deployment_maximum_percent         = 200 # 最大稼働率（新旧タスクの合計がdesired_countの200%まで許容）

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # ネットワーク設定
  network_configuration {
    subnets = [
      data.aws_subnet.private_subnet_1a.id,
      data.aws_subnet.private_subnet_1c.id
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false # NATゲートウェイを使うため
  }

  # ロードバランサー設定
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "${var.project}-${var.environment}-container"
    container_port   = 80
  }

  # TerraformとCI/CD（CodePipeline）の競合対策
  lifecycle {
    ignore_changes = [
      task_definition, # CodePipelineによるタスク定義リビジョン更新を上書きしないため
      desired_count    # 手動やオートスケーリングによるタスク個数変更を上書きしないため
    ]
  }

  tags = {
    Name    = "${var.project}-${var.environment}-ecs-service"
    Project = var.project
    Env     = var.environment
  }
}
