variable "profile" {
  description = "Local AWS profile name"
  type        = string
  default     = "default"
}

variable "region" {
  description = "Target AWS region"
  type        = string
  default     = "us-east-1"
}

variable "GitHub" {
  description = "Information to connect to GitHub repo to use for AWS CodePipeline"
  type        = map
}

variable "s3_bucket_name" {
  description = "S3 bucket name for website's source files. Must be unique."
  type        = string
}

variable "force_destroy" {
  description = "Assign True to force deletion of S3 buckets with files on terraform destroy"
  type        = bool
  default     = true
}
variable "tags" {
  description = "Dict of tags"
  type        = map(string)
  default = {
    Name = "Terraform-AWS-CICD-website"
  }
}