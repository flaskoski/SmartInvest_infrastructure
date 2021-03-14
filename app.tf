
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
        Name = "${var.tf_prefix}ec2_transactions${count.index}"
        AppGroup = var.appGroup
        AppName = var.appName
    }
    # vpc_security_group_ids=["sg-e3309b92"]
    vpc_security_group_ids=[aws_security_group.default_sg.id]
    iam_instance_profile = aws_iam_instance_profile.transactions_ec2_profile.name
}

resource "aws_iam_instance_profile" "transactions_ec2_profile" {
  name = "${var.tf_prefix}profile-ec2-transactions"
  role = aws_iam_role.transactions_ec2_deploy_role.name
}

resource "aws_iam_role" "transactions_ec2_deploy_role" {
  name = "${var.tf_prefix}role-ec2-codedeploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.transactions_ec2_deploy_role.name
}

resource "aws_iam_role_policy" "transactions_rds_policy" {
  name = "${var.tf_prefix}policy-rds-transactions"
  role = aws_iam_role.transactions_ec2_deploy_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "rds:*",
            "Resource": aws_db_instance.transactions_rds.arn
        }
    ]
  })
}
resource "aws_iam_role_policy" "transactions_ec2_codedeploy_policy" {
  name = "${var.tf_prefix}policy-ec2-deploy-transactions"
  role = aws_iam_role.transactions_ec2_deploy_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "cloudformation:DescribeStackResources"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_security_group" "default_sg" {
    name        = "${var.tf_prefix}default_sg"
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

resource "aws_db_instance" "transactions_rds" {
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t2.micro"
    name                 = "dbSmartinvest"
    # identifier           = "db-smartinvest"
    username             = aws_ssm_parameter.ssm_db_smartinvest_username.value
    password             = aws_ssm_parameter.ssm_db_smartinvest_password.value
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot  = true
    publicly_accessible = true
    vpc_security_group_ids=[aws_security_group.default_sg.id]
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
resource "aws_ssm_parameter" "ssm_apikey_alpha" {
  name  = "${var.tf_prefix}API_KEY_ALPHA"
  type  = "SecureString"
  value = var.apikey_alpha
  overwrite = true
}
resource "aws_ssm_parameter" "ssm_aws_account_id" {
  name  = "${var.tf_prefix}aws_account_id"
  type  = "SecureString"
  value = var.aws_account_id
  overwrite = true
}