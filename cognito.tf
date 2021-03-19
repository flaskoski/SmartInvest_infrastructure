//-----------vars--------------------------------
variable cognito_pool_id {
  type        = string
  sensitive   = true
  description = "Smart Invest Cognito User Pool ID"
}

//---SSM Parameter Store--------------------------
resource "aws_ssm_parameter" "ssm_cognito_pool_id" {
    name  = "${var.tf_prefix}smartinvest_cognito_pool_id"
    type  = "SecureString"
    value = var.cognito_pool_id
    overwrite = true
}


//-----------cognito resources------------------
resource "aws_cognito_user_pool" "smartinvest_user_pool" {
    name = "smartinvest-users"
    schema {
        attribute_data_type = "String"
        developer_only_attribute = false
        mutable = true
        name = "email"
        required = true

        string_attribute_constraints{
            max_length = "2048"
            min_length = "0"
        }
    }
    auto_verified_attributes = ["email",]
    password_policy {
        minimum_length                   = 8 
        require_lowercase                = true
        require_numbers                  = true
        require_symbols                  = false
        require_uppercase                = true
        temporary_password_validity_days = 2
    }
    account_recovery_setting {
        recovery_mechanism {
            name     = "verified_email"
            priority = 1
        }
    }
    username_configuration {
        case_sensitive = false
    }
}

resource "aws_cognito_user_pool_client" "smartinvest_user_pool_client" {
    name = "smartinvest"
    user_pool_id = aws_cognito_user_pool.smartinvest_user_pool.id
    callback_urls = [var.smartinvest_cloudfront_endpoint,]
    logout_urls = [var.smartinvest_cloudfront_endpoint,]
    supported_identity_providers = ["COGNITO"]
    explicit_auth_flows = [
        "ALLOW_CUSTOM_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_SRP_AUTH",
    ]
    # allowed_oauth_scopes = [
    #     "aws.cognito.signin.user.admin",
    #     "email",
    #     "profile",
    # ]
    read_attributes = [
        "email",
        "email_verified",
        "name",
        "nickname",
        "preferred_username",
        "profile",
        "updated_at",
        ]
    write_attributes = [
        "email",
        "name",
        "nickname",
        "preferred_username",
        "profile",
        "updated_at",
    ]
}