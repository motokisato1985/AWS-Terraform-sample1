# ---------------------------------
# Allowed IP set (dev / office IP)
# ---------------------------------

resource "aws_wafv2_ip_set" "allowed_ip_set" {
  provider           = aws.virginia
  name               = "${var.project}-${var.environment}-allowed-ip-set"
  description        = "Allowed office/public IPs for dev environment"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  addresses = [
    # 社内IPをtfvarsのallowed_ip_cidrsに記載する
    for ip in var.allowed_ip_cidrs : ip
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-allowed-ip-set"
    Project = var.project
    Env     = var.environment
  }
}

# -----------------------------------------------------------------
# WAF Web ACL for CloudFront
# 優先度1 (block-non-japan): 日本以外からのアクセスなら 遮断
# 優先度2 (allow-specific-ip): 日本かつ許可IPリストに含まれるなら 許可
# デフォルトアクション: それ以外はすべて 遮断
# -----------------------------------------------------------------
resource "aws_wafv2_web_acl" "cf_waf" {
  provider    = aws.virginia
  name        = "${var.project}-${var.environment}-cf-waf"
  description = "WAF for dev CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

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

  # ネットワーク診断用許可設定
  rule {
    name     = "allow-specific-ip"
    priority = 2

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-allow-specific-ip"
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
