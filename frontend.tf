//---------vars------------------------------

variable smartinvest_website_bucket_name {
  type        = string
  description = "s3 bucket name for the static site"
}
variable smartinvest_cloudfront_endpoint {
  type        = string
  description = "smartinvest cloudfront endpoint url"
}

//---SSM Parameter Store---------------------
resource "aws_ssm_parameter" "ssm_smartinvest_website_url" {
    name  = "${var.tf_prefix}smartinvest_website_url"
    type  = "String"
    value = var.smartinvest_website_bucket_name
    overwrite = true
}
resource "aws_ssm_parameter" "ssm_smartinvest_website_bucket_name" {
    name  = "${var.tf_prefix}smartinvest_website_bucket_name"
    type  = "String"
    value = var.smartinvest_website_bucket_name
    overwrite = true
}

//----------Smart Invest UI bucket--------------------
resource "aws_s3_bucket" "smartinvest-s3-site" {
    bucket = var.smartinvest_website_bucket_name
    acl    = "public-read"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "elasticloadbalancing.amazonaws.com",
                        "ec2.amazonaws.com",
                        "cloudfront.amazonaws.com"
                    ]
                },
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::${var.smartinvest_website_bucket_name}/*"
            }
        ]
    })
    website {
        index_document = "index.html"
        error_document = "index.html"
    }
}