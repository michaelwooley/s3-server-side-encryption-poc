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
  profile = "test-account"
  region  = "us-east-1"
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key
resource "aws_kms_key" "bucket_sse" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "b" {
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
