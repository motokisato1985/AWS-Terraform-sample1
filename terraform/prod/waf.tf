# ---------------------------------
# WAF Web ACL for CloudFront
# - 日本以外をブロック
# - AWS Managed Rules により一般的な脆弱性攻撃を防御
# - レート制限により短時間の大量リクエストを遮断
# ---------------------------------
resource "aws_wafv2_web_acl" "cf_waf" {
  provider    = aws.virginia
  name        = "${var.project}-${var.environment}-cf-waf"
  description = "WAF for ${var.environment} CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # ---------------------------------
  # 日本以外のアクセスをブロック
  # ---------------------------------
  rule {
    name     = "block-non-japan"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["JP"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-block-non-japan"
      sampled_requests_enabled   = true
    }
  }

  # ---------------------------------
  # AWS Managed Rules
  # SQLi / XSS / 一般的な脆弱性攻撃への対策
  # ---------------------------------
  rule {
    name     = "aws-managed-common"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-aws-managed-common"
      sampled_requests_enabled   = true
    }
  }

  # ---------------------------------
  # レート制限
  # 短時間の大量リクエストをIP単位で遮断
  # 例: 5分間に1000リクエスト超でブロック
  # ---------------------------------
  rule {
    name     = "rate-limit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-cf-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = "${var.project}-${var.environment}-cf-waf"
    Project = var.project
    Env     = var.environment
  }
}
