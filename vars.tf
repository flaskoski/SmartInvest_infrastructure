variable key_pair {
  type        = string
  default     = "node-demo"
  description = "smart-invest EC2 instances key pair"
}

variable allowed_ips {
  type        = list
  default     = ["191.177.185.105/32"]
  description = "Allowed ips to communicate to the VPC"
}

variable springboot_transactions_ssm_params_prefix {
    type      = string
    default   = "/config/Transactions/"
}

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