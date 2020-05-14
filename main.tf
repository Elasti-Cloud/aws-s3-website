terraform {
  required_version = ">=0.12.0"
}

provider "aws" {
  version = "~> 2.0"
  profile = var.profile
  region  = var.region
}

# Creating S3 bucket for website's source files
resource "aws_s3_bucket" "web_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"
}

# Creating a simple index.html file and uploading to the S3 bucket
resource "aws_s3_bucket_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOF
<html xmlns="http://www.w3.org/1999/xhtml" lang=en>
<head>
    <title>Sample Website</title>
</head>
<body>
  <h1>Welcome to my website deployed with Terraform</h1>
  <p>Now hosted on Amazon S3!</p>
</body>
</html>
EOF
}

# Creating AWS CloudFront distribution
locals {
  s3_origin_id = "webS3Origin"
}

resource "aws_cloudfront_origin_access_identity" "web_origin_ai" {
  comment = "Origin access identity for the S3 bucket"
}

resource "aws_cloudfront_distribution" "web_distribution" {
  origin {
    domain_name = aws_s3_bucket.web_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_origin_ai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.web_bucket.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_cloudfront_origin_access_identity.web_origin_ai.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.s3_bucket_name}/*"
        }
    ]
}
EOF
}
