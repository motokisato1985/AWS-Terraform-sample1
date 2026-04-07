#---------------------------------------------
# AWS Certificate Manager
#---------------------------------------------

#-------------------------------------
# 東京リージョン用証明書（ALB用）
#-------------------------------------

resource "aws_acm_certificate" "tokyo_cert" {
  domain_name       = "${var.subdomain}.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-tokyo-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 東京リージョン用 ACM の DNS 検証レコード
resource "aws_route53_record" "tokyo_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 300
  records         = [each.value.record]
}

# 東京リージョン用 ACM の検証実行
resource "aws_acm_certificate_validation" "tokyo_cert_validation" {
  certificate_arn         = aws_acm_certificate.tokyo_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.tokyo_cert_validation : record.fqdn]
}

#---------------------------------------------
# バージニアリージョン用証明書（CloudFront用）
#---------------------------------------------
resource "aws_acm_certificate" "virginia_cert" {
  provider          = aws.virginia
  domain_name       = "${var.subdomain}.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-virginia-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# バージニアリージョン用 ACM の DNS 検証レコード
resource "aws_route53_record" "virginia_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.virginia_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 300
  records         = [each.value.record]
}

# バージニアリージョン用 ACM の検証実行
resource "aws_acm_certificate_validation" "virginia_cert_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.virginia_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.virginia_cert_validation : record.fqdn]
}
