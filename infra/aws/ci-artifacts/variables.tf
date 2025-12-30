variable "aws_region" {
  type        = string
  description = "AWS region for the bucket and IAM resources"
  default     = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Unique S3 bucket name for deploy artifacts"
}

variable "role_name" {
  type        = string
  description = "IAM role name to be assumed by GitHub Actions"
  default     = "github-actions-artifacts-uploader"
}

variable "github_org" {
  type        = string
  description = "GitHub organization/user that owns the repo"
  default     = "DanielWillian"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "spring-app-deploy"
}
