//global
variable environment {
  type        = string
  default     = "dev"
  description = "description"
}
variable region {
  type        = string
  default     = "sa-east-1"
  description = "region used"
}
variable tf_prefix {
  type        = string
  default     = "tf-"
  description = "description"
}

variable appGroup {
  type        = string
  default     = "SmartInvest"
  description = "app group name"
}
variable appName {
  type        = string
  default     = "Transactions"
  description = "app name"
}



//compute (ec2/rds)
variable key_pair {
  type        = string
  default     = "node-demo"
  description = "smart-invest EC2 instances key pair"
}

variable allowed_ips {
  type        = list
  description = "Allowed ips to communicate to the VPC"
}

variable springboot_transactions_ssm_params_prefix {
    type      = string
    default   = "/config/Transactions/"
}

//----ssm parameters

variable db_smartinvest_username {
  description = "SmartInvest Database username"
  type        = string
  sensitive   = true
}
variable db_smartinvest_password {
  description = "SmartInvest Database password"
  type        = string
  sensitive   = true
}
variable apikey_alpha {
  description = "Alphavantage API KEY"
  type        = string
  sensitive   = true
}
variable aws_account_id {
  type        = string
  description = "my account id"
  sensitive   = true
}
variable cognito_pool_id {
  type        = string
  sensitive   = true
  description = "Smart Invest Cognito User Pool ID"
}
variable smartinvest_website_bucket_name {
  type        = string
  description = "s3 bucket name for the static site"
}
variable smartinvest_cloudfront_endpoint {
  type        = string
  description = "smartinvest cloudfront endpoint url"
}


# Codepipeline vars
variable github_address {
  type        = string
  default     = "https://github.com/flaskoski/Transactions.git"
  description = "description"
}
variable github_repo_path {
  type        = string
  default     = "flaskoski/Transactions"
  description = ""
}
