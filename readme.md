# Smart Invest Transactions Infrastructure

### Installation 

1. Install terraform 0.1.4 or above

1. Configure your AWS credentials

1. Create a `.tfvars` file with the following keys:
    1. `db_smartinvest_username`: RDS instance username
    1. `db_smartinvest_password`: RDS instance password
    1. `apikey_alpha`: AlphaVantage API Key
    1. `aws_account_id`: AWS account id
    1. `cognito_pool_id`: cognito user pool id. Ex: "sa-east-1_a3ER3rrQa"
    1. `allowed_ips`: list of allowed ips to access the default security group. Ex: ["191.10.223.120/32", "167.112.78.224/32"]
    1. `smartinvest_website_bucket_name`: website bucket name. Ex: "my-static-website"
    1. `smartinvest_cloudfront_endpoint`: Cloudfront DNS url. Ex: "https://abc1def2fgh3ij.cloudfront.net/"

1. Apply infra to the provider: `terraform apply -var-file="yourFile.tfvars"`

### Smart Invest Terraform Infrastructure diagram

![infra diagram](https://github.com/flaskoski/SmartInvest_infrastructure/blob/master/images/diagram.v2.png)