variable "bucket_name" {
  type        = string
  description = "Bucket name"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  sensitive   = false
  description = "AWS region"
}

variable "aws_account_id" {
  type        = string
  sensitive   = true
  description = "AWS Saccount ID"
}


variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS Access key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS Secret Access key"
}
