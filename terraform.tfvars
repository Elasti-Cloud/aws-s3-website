profile        = "YOUR_LOCAL_AWS_PROFILE_NAME_HERE"
region         = "us-east-1"
s3_bucket_name = "YOUR_S3BUCKET_WEBSITE_NAME_HERE"
force_destroy  = true
GitHub = {
  Owner  = "YOUR_GITHUB_USERNAME_HERE"
  Repo   = "YOUR_REPO_WITH_WEBSITE_HERE"
  Branch = "master"
  Token  = "YOUR_GITHUB_TOKEN_HERE"
}
tags = {
  Name = "Terraform-AWS-CICD-website"
}
