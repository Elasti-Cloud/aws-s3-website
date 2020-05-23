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

variable "GitHub_token" {
  description = "GitHub token to use for AWS CodePipeline"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for website's source files. Must be unique."
  type        = string
  default     = "aws-s3-website-sample007"
}

variable "sample_web_site" {
  description = "S3 bucket address with the source code for the web site"
  type        = string
  default     = "s3://wildrydes-us-east-1/WebApplication/1_StaticWebHosting/website"
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
    Name = "Terraform"
  }
}