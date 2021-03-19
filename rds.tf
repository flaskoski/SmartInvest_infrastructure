//---vars
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

//---SSM Parameter Store
resource "aws_ssm_parameter" "ssm_db_smartinvest_username" {
    name  = "${var.springboot_transactions_ssm_params_prefix}${var.tf_prefix}RDS_SMARTINVEST_username"
    type  = "SecureString"
    value = var.db_smartinvest_username
    overwrite = true
}
resource "aws_ssm_parameter" "ssm_db_smartinvest_password" {
    name  = "${var.springboot_transactions_ssm_params_prefix}${var.tf_prefix}RDS_SMARTINVEST_PASSWORD"
    type  = "SecureString"
    value = var.db_smartinvest_password
    overwrite = true
}
resource "aws_ssm_parameter" "ssm_db_smartinvest_url" {
    name = "${var.springboot_transactions_ssm_params_prefix}${var.tf_prefix}RDS_SMARTINVEST_URL"
    value = "${aws_db_instance.transactions_rds.endpoint}/${aws_db_instance.transactions_rds.name}"
    type  = "String"
    overwrite = true
}


//----------------------RDS------------------------
resource "aws_db_instance" "transactions_rds" {
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t2.micro"
    name                 = "dbSmartinvest"
    port                 = 3306
    identifier           = "${var.tf_prefix}db-transactions"
    username             = aws_ssm_parameter.ssm_db_smartinvest_username.value
    password             = aws_ssm_parameter.ssm_db_smartinvest_password.value
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot  = true
    publicly_accessible = true
    vpc_security_group_ids=[aws_security_group.default_sg.id]
}
