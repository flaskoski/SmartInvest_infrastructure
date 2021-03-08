
provider "aws" {
    region = "sa-east-1"
}

resource "aws_instance" "transactions_ec2" {
    count = 1
    ami = "ami-0a0bc0fa94d632c94"
    instance_type = "t2.micro"
    key_name = var.key_pair
    user_data = file("./install_java.sh")
    tags = {
        Name = "ec2_transactions${count.index}"
    }
    # vpc_security_group_ids=["sg-e3309b92"]
    vpc_security_group_ids=[aws_security_group.default_sg.id]

}

resource "aws_security_group" "default_sg" {
    name        = "default_sg"
    description = "Allow inbound traffic from default_sg and specific ip. Outbound traffic to anywhere"
    #vpc_id      = aws_vpc.main.id

    ingress {
    #description = "TLS from VPC"
        from_port   = 0
        to_port     = 65000
        protocol    = "tcp"
        cidr_blocks = var.allowed_ips
    }
    ingress {
        #description = "TLS from VPC"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "default_sg"
    }
}

resource "aws_db_instance" "smartinvest_rds" {
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t2.micro"
    name                 = "dbSmartinvest"
    # identifier           = "db-smartinvest"
    username             = aws_ssm_parameter.db_smartinvest_username.value
    password             = aws_ssm_parameter.db_smartinvest_password.value
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot  = true
    publicly_accessible = true
    vpc_security_group_ids=[aws_security_group.default_sg.id]
}


//---SSM Parameter Store
resource "aws_ssm_parameter" "db_smartinvest_username" {
  name  = "${var.springboot_transactions_ssm_params_prefix}RDS_SMARTINVEST_username_terraform"
  type  = "SecureString"
  value = var.db_smartinvest_username
  overwrite = true
}
resource "aws_ssm_parameter" "db_smartinvest_password" {
  name  = "${var.springboot_transactions_ssm_params_prefix}RDS_SMARTINVEST_PASSWORD_terraform"
  type  = "SecureString"
  value = var.db_smartinvest_password
  overwrite = true
}
resource "aws_ssm_parameter" "apikey_alpha" {
  name  = "API_KEY_ALPHA"
  type  = "SecureString"
  value = var.apikey_alpha
  overwrite = true
}