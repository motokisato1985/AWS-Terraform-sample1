#------------------------------
# CloudFront cache distribution
#------------------------------
# - ALB をオリジンとして HTTPS 経由でアクセス
# - ビューワーは HTTPS のみ許可
# - WAF で日本以外からのアクセスをブロック

resource "aws_cloudfront_distribution" "cf" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "development distribution"
  price_class     = var.cf_price_class

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = aws_lb.alb.name

    custom_origin_config {
      http_port              = var.cf_origin_http_port
      https_port             = var.cf_origin_https_port
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers = [
        "Host",
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
      cookies {
        forward = "all"
      }
    }

    target_origin_id       = aws_lb.alb.name
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["${var.subdomain}.${var.domain}"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.virginia_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.cf_waf.arn

  tags = {
    Name    = "${var.project}-${var.environment}-cloudfront"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route53_record" "route53_cloudfront" {
  zone_id = var.route53_zone_id
  name    = "${var.subdomain}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}

