output "domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = "http://${aws_cloudfront_distribution.web_distribution.domain_name}"
}