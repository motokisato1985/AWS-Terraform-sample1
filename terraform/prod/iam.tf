# ----------------------------------------------------------------------------------
# IAM Role (Task Execution Role) - ECSがECRからイメージを取得したり、ログを吐くための権限
# ----------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 標準のポリシー（ECR操作・ログ出力）をアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# SSM / Secrets Manager 読み取り権限
resource "aws_iam_policy" "ssm_read" {
  name        = "${var.project}-${var.environment}-ssm-read-policy"
  description = "Allow ECS to read from Parameter Store, Secrets Manager and decrypt KMS keys"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.app_key.arn,
          aws_db_instance.mysql.master_user_secret[0].secret_arn
        ]
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_read_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

# -------------------------------------------------------
# IAM Role - CodeBuild Service Role
# -------------------------------------------------------
resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild-${var.project}-${var.environment}-build-project-service-role"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ---------------------------------------------------------------------
# IAM Inline Policy - CodeBuildからECRへイメージPushするための権限
# ---------------------------------------------------------------------
resource "aws_iam_role_policy" "codebuild_ecr_build_policy" {
  name = "${var.project}-${var.environment}-ecr-build-policy"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------------------
# ECS task role - CodeBuildからECSのRunTaskを実行するための権限
# ---------------------------------------------------------------------
resource "aws_iam_role_policy" "codebuild_ecs_runtask_policy" {
  name = "${var.project}-${var.environment}-ecs-runtask-policy"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRunTask"
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          aws_ecs_task_definition.ecs_task.arn,
          "${aws_ecs_task_definition.ecs_task.arn}:*",
          aws_ecs_task_definition.ecs_migration_task.arn,
          "${aws_ecs_task_definition.ecs_migration_task.arn}:*",
          aws_ecs_cluster.ecs_cluster.arn,
          "${aws_ecs_cluster.ecs_cluster.arn}:*"
        ]
      },
      {
        Sid    = "AllowPassExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn
        ]
      }
    ]
  })
}

# ---------------------------------------------------------------------------------------
# IAM Role (CodePipeline Service Role) - CodePipelineがECSのサービス更新を実行するための権限
# ---------------------------------------------------------------------------------------
resource "aws_iam_role" "codepipeline_service_role" {
  name = "${var.project}-${var.environment}-pipeline-role"

  # 信頼関係 (CodePipelineがこのロールを使えるようにする)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# ---------------------------------------------------------
# IAM Policy (Inline Policy)
# ---------------------------------------------------------
resource "aws_iam_role_policy" "codepipeline_inline_policy" {
  name = "${var.project}-${var.environment}-pipeline-policy"
  role = aws_iam_role.codepipeline_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. CodeConnections (GitHubへのアクセス権限)
      {
        Effect   = "Allow"
        Action   = "codestar-connections:UseConnection"
        Resource = var.codestar_connection_arn
      },

      # 2. ECS操作権限
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:TagResource"
        ]
        Resource = "*"
      },

      # 3. S3 (アーティファクトバケット) へのアクセス権限
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ]
        Resource = "*"
      },

      # 4. CodeBuildを実行する権限
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },

      # 5. ECSタスク実行ロールをECSに渡す権限
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}
