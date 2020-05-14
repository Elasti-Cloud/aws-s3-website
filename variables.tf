variable "profile" {
  description = "Local AWS profile name"
  type        = string
  default     = "default"
}

variable "region" {
  description = "Target AWS region"
  type        = string
  default     = "us-west-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for website's source files. Must be unique."
  type        = string
  default     = "aws-s3-website-sample001"
}

variable "tags" {
  description = "Dict of tags"
  type        = map(string)
  default = {
    Name = "Terraform"
  }
}