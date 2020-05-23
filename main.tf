terraform {
  required_version = ">=0.12"
}

provider "aws" {
  version = ">= 2.0"
  region  = var.region
  profile = var.profile
}

# Creating S3 bucket for website's source files
resource "aws_s3_bucket" "web_bucket" {
  bucket        = var.s3_bucket_name
  acl           = "private"
  force_destroy = var.force_destroy
  tags          = var.tags
}
# Creating S3 bucket for CodePipeline
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "codepipeline-bucket-${var.s3_bucket_name}"
  acl           = "private"
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-github-s3"
  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-github-s3-policy"
  role = aws_iam_role.codepipeline_role.id
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.web_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*",
        "${aws_s3_bucket.web_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

data "aws_kms_alias" "s3kmskey" {
  name = "alias/aws/s3"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "terraform-github-s3-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  tags     = var.tags

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "Elasti-Cloud"
        Repo       = "web_site"
        Branch     = "master"
        OAuthToken = var.GitHub_token
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = var.s3_bucket_name
        Extract    = true
      }
    }
  }
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