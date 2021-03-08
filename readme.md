# Smart Invest Transactions Infrastructure

### Installation 

1. Install terraform 0.1.4 or above

1. Configure your AWS credentials

1. Create a `.tfvars` file with the following keys:
    1. `db_smartinvest_username`: RDS instance username
    1. `db_smartinvest_password`: RDS instance password
    1. `apikey_alpha`: AlphaVantage API Key

1. Apply infra to the provider: `terraform apply -var-file="yourFile.tfvars"`