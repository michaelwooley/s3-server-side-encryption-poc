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


resource "aws_cloudfront_origin_access_identity" "sse_oai" {
  comment = "Access the bucket"
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = var.bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_object" "test_object" {
  key          = "index.html"
  bucket       = aws_s3_bucket.test_bucket.id
  source       = "static/index.html"
  content_type = "html"
}

resource "aws_s3_bucket_policy" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id

  policy = jsonencode(
    {
      Id = "PolicyForCloudFrontPrivateContent"
      Statement = [
        {
          Action = "s3:GetObject"
          Effect = "Allow"
          Principal = {
            AWS = [aws_cloudfront_origin_access_identity.sse_oai.iam_arn]
          }
          Resource = "${aws_s3_bucket.test_bucket.arn}/*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.test_bucket.bucket}.s3.${aws_s3_bucket.test_bucket.region}.amazonaws.com"
    origin_id   = "s3-${aws_s3_bucket.test_bucket.id}"
    origin_path = ""

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.sse_oai.cloudfront_access_identity_path
    }
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

