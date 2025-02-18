locals {
  resource_prefix = "ky-tf"
}

resource "aws_wafv2_ip_set" "ip_set" {
  name               = "${local.resource_prefix}-ipset"
  scope              = "REGIONAL" # Use "CLOUDFRONT" for global (CloudFront)
  description        = "An IP set"
  ip_address_version = "IPV4" # Use IPV6 if you need to support IPv6

  addresses = [
    "${trimspace(data.http.public_ip.response_body)}/32"
  ]

  tags = {
    Name = "${local.resource_prefix}-ipset"
  }
}

resource "aws_wafv2_web_acl" "webapp_acl" {
  name  = "${local.resource_prefix}-webapp-acl"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "allow-ip"
    priority = 3
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ip_set.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-webapp-acl-allow-ip"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "BlockAdminPath"
    priority = 2
    action {
      block {}
    }
    statement {
      byte_match_statement {
        search_string = "/admin"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "ENDS_WITH"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-webapp-acl-block-admin"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-AmazonIpReputationListMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.resource_prefix}-webapp-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${local.resource_prefix}-webapp-acl"
  }


}

resource "aws_wafv2_web_acl_association" "aws_resource" {
  resource_arn = data.aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.webapp_acl.arn
}