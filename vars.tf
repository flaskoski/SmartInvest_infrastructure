//----global vars
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

//----ssm parameters

variable apikey_alpha {
  description = "Alphavantage API KEY"
  type        = string
  sensitive   = true
}
resource "aws_ssm_parameter" "ssm_apikey_alpha" {
    name  = "${var.tf_prefix}API_KEY_ALPHA"
    type  = "SecureString"
    value = var.apikey_alpha
    overwrite = true
}


variable aws_account_id {
  type        = string
  description = "my account id"
  sensitive   = true
}
resource "aws_ssm_parameter" "ssm_aws_account_id" {
    name  = "${var.tf_prefix}aws_account_id"
    type  = "SecureString"
    value = var.aws_account_id
    overwrite = true
}
