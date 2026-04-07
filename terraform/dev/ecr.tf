# ---------------------------------------------
# ECR Repository
# ---------------------------------------------
resource "aws_ecr_repository" "laravel_repo" {
  name                 = "${var.project}-${var.environment}-laravel-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project}-${var.environment}-laravel-repo"
    Project = var.project
    Env     = var.environment
  }
}

# ---------------------------------------------
# ECR Lifecycle Policy (オプション：イメージの自動削除設定)
# ---------------------------------------------
resource "aws_ecr_lifecycle_policy" "laravel_repo_policy" {
  repository = aws_ecr_repository.laravel_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 5 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
