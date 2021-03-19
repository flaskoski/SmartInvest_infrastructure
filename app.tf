
//----------------------EC2/ALB/VPC------------------------
//---------------------------------------------------------
provider "aws" {
    region = var.region
}

//-------vars---------------------------------------------
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

//---SSM Parameter Store------------------------------------
resource "aws_ssm_parameter" "ssm_transactions_lb_url" {
    name  = "${var.tf_prefix}transactions_lb_url"
    type  = "String"
    value = aws_lb.transactions_lb.dns_name
    overwrite = true
}

//---------VPC------------------------------------
resource "aws_vpc" "transactions_vpc" {
  cidr_block = "172.31.0.0/16"

#   tags = {
#     Name = ""
#   }
}

//---------EC2------------------------------------
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
//--EC2 policies
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
//--security group
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

//---------ELB------------------------------------
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
        path                = "/actuator"
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
//--ssl certificate
resource "aws_iam_server_certificate" "smartinvest_cert" {
    name_prefix      = "cert-smartinvest"
    certificate_body = file("cert/smartinvest-cert.pem")
    private_key      = file("cert/smartinvest-key.pem")
    lifecycle {
        create_before_destroy = true
    }
}



