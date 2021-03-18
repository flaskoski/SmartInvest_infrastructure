
provider "aws" {
    region = var.region
}

resource "aws_vpc" "transactions_vpc" {
  cidr_block = "172.31.0.0/16"

#   tags = {
#     Name = ""
#   }
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
        },{
            "Effect": "Allow",
            "Action": [
                "ssm:GetParametersByPath",
                "ssm:GetParameter"],
            "Resource": "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/*"
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

//----------------------ELB------------------
resource "aws_lb_target_group" "transactions_tg"{
    name = "${var.tf_prefix}tg-transactions"
    port                               = 8080 
    protocol                           = "HTTP"
    protocol_version                   = "HTTP1"
    vpc_id                             = aws_vpc.transactions_vpc.id
    health_check {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
    }
}
resource "aws_lb" "transactions_lb" {
    name = "${var.tf_prefix}elb-transactions"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.default_sg.id]
}
resource "aws_lb_listener" "transactions_lb_listener" {
  load_balancer_arn = aws_lb.transactions_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_iam_server_certificate.smartinvest_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.transactions_tg.arn
  }
}
resource "aws_iam_server_certificate" "smartinvest_cert" {
    name_prefix      = "cert-smartinvest"
    certificate_body = file("cert/smartinvest-cert.pem")
    private_key      = file("cert/smartinvest-key.pem")
    lifecycle {
        create_before_destroy = true
    }
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
resource "aws_ssm_parameter" "ssm_cognito_pool_id" {
    name  = "${var.tf_prefix}smartinvest_cognito_pool_id"
    type  = "SecureString"
    value = var.cognito_pool_id
    overwrite = true
}
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
resource "aws_ssm_parameter" "ssm_transactions_lb_url" {
    name  = "${var.tf_prefix}transactions_lb_url"
    type  = "String"
    value = aws_lb.transactions_lb.dns_name
    overwrite = true
}

//----------Smart Invest UI-------------
resource "aws_s3_bucket" "smartinvest-s3-site" {
    bucket = var.smartinvest_website_bucket_name
    acl    = "public-read"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
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