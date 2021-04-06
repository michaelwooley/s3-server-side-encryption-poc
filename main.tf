terraform {
  backend "local" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.35.0"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}


// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
resource "aws_kms_key" "bucket_sse" {
  description              = "This key is used to encrypt bucket objects"
  enable_key_rotation      = true
  is_enabled               = true
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
  policy                   = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.aws_account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access through S3 for all principals in the account that are authorized to use S3",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:CallerAccount": "${var.aws_account_id}",
                    "kms:ViaService": "s3.${var.aws_region}.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.bucket_sse.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}


resource "aws_s3_bucket_object" "examplebucket_object" {
  key    = "index.html"
  bucket = aws_s3_bucket.test_bucket.id
  source = "static/index.html"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.test_bucket.bucket}.s3.${aws_s3_bucket.test_bucket.region}.amazonaws.com"
    origin_id   = "s3-${aws_s3_bucket.test_bucket.id}"
    origin_path = ""

    custom_origin_config {
      https_port             = 443
      http_port              = 80
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    // s3_origin_config {
    // origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
    // }
  }

  enabled         = true
  http_version    = "http1.1"
  is_ipv6_enabled = true
  comment         = "Test serving bucket"

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET", "OPTIONS"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    target_origin_id       = "s3-${aws_s3_bucket.test_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

