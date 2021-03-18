//-------CodePipeline-----------------------

resource "aws_codepipeline" "transactions_pipeline" {
  name     = "${var.tf_prefix}pipeline-smartinvest-transactions"
  role_arn = aws_iam_role.transactions_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.transactions_codepipeline_bucket.bucket
    type     = "S3"
#     encryption_key {
#       id   = data.aws_kms_alias.s3kmskey.arn
#       type = "KMS"
#     }
  }
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection" # for github connection
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.transactions_github_connection.arn
        FullRepositoryId = var.github_repo_path
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.transactions_build_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName= aws_codedeploy_app.transactions_codedeploy_app.name
        DeploymentGroupName   = aws_codedeploy_deployment_group.transactions_codedeploy_group.deployment_group_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "transactions_github_connection" {
  name          = "tf-transactions-git-connection"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "transactions_codepipeline_bucket" {
  bucket = "${var.tf_prefix}s3-codepipeline-transactions"
  acl    = "private"
}

resource "aws_iam_role" "transactions_codepipeline_role" {
  name = "${var.tf_prefix}codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "transactions_codepipeline_policy" {
  name = "${var.tf_prefix}codepipeline-policy"
  role = aws_iam_role.transactions_codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.transactions_codepipeline_bucket.arn}",
        "${aws_s3_bucket.transactions_codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "appconfig:StartDeployment",
            "appconfig:StopDeployment",
            "appconfig:GetDeployment"
        ],
        "Resource": "*"
    },
    {
        "Action": [
            "codedeploy:CreateDeployment",
            "codedeploy:GetApplication",
            "codedeploy:GetApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": [
            "codestar-connections:UseConnection"
        ],
        "Resource": "${aws_codestarconnections_connection.transactions_github_connection.arn}",
        "Effect": "Allow"
    },
    {
        "Action": [
            "ec2:*"
        ],
        "Resource": ["${join("\",\"", aws_instance.transactions_ec2[*].arn)}"],
        "Effect": "Allow"
    }
  ]
}
EOF
}

//---------CodeDeploy---------------------

resource "aws_codedeploy_app" "transactions_codedeploy_app" {
  compute_platform = "Server"
  name             = "${var.tf_prefix}codedeploy-app-transactions"
}

resource "aws_codedeploy_deployment_group" "transactions_codedeploy_group" {
  app_name              = aws_codedeploy_app.transactions_codedeploy_app.name
  deployment_group_name = "${var.tf_prefix}-codedeploy-group-transactions"
  service_role_arn      = aws_iam_role.transactions_codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      type  = "KEY_AND_VALUE"
      key   = "AppGroup"
      value = var.appGroup
    }

    ec2_tag_filter {
      type  = "KEY_AND_VALUE"
      key   = "AppName"
      value = var.appName
    }
  }

#   trigger_configuration {
#     trigger_events     = ["DeploymentFailure"]
#     trigger_name       = "${var.tf_prefix}trigger-deploy-failure-transactions"
#     trigger_target_arn = aws_sns_topic.transactions_snstopic_deployment.arn
#   }

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }

#   alarm_configuration {
    # alarms  = ["my-alarm-name"]
    # enabled = false
#   }
}

resource "aws_sns_topic" "transactions_snstopic_deployment" {
  name = "${var.tf_prefix}sns-topic-deploy-transactions"
}

resource "aws_iam_role" "transactions_codedeploy_role" {
  name = "${var.tf_prefix}role-codedeploy-transactions"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.transactions_codebuild_role.name
}

//------CodeBuild--------

resource "aws_codebuild_project" "transactions_build_project" {
  name          = "${var.tf_prefix}build-project-transactions"
  description   = "project for terraform codebuild step of transactions"
  build_timeout = "5"
  service_role  = aws_iam_role.transactions_codebuild_role.arn

  artifacts {
    type =  "S3" #"NO_ARTIFACTS"
    location = aws_s3_bucket.transactions_codepipeline_bucket.bucket
    packaging = "ZIP"
    path = "/build-artifacts"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.transactions_codepipeline_bucket.bucket}/build-cache"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # environment_variable {
    #   name  = "SOME_KEY1"
    #   value = "SOME_VALUE1"
    # }

    # environment_variable {
    #   name  = "SOME_KEY2"
    #   value = "SOME_VALUE2"
    #   type  = "PARAMETER_STORE"
    # }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
      group_name  = "${var.tf_prefix}log-group-codebuild-transactions"
      stream_name = "${var.tf_prefix}log-stream-codebuild-transactions"
    }
    # s3_logs {
    #   status   = "ENABLED"
    #   location = "${aws_s3_bucket.transactions_codepipeline_bucket.bucket}/build-log"
    # }
  }

  source {
    type            = "GITHUB"
    location        = var.github_address
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = "master"

#   vpc_config {
#     vpc_id = aws_vpc.example.id
#     subnets = [ aws_subnet.example1.id]
#     security_group_ids = [aws_security_group.example1.id]
#   }

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "transactions_codebuild_role" {
  name = "${var.tf_prefix}role-codebuild-transactions"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "transactions_codebuild_policy" {
  role = aws_iam_role.transactions_codebuild_role.name
  name = "${var.tf_prefix}policy-codebuild-transactions"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
      ],
      "Resource": [
        "${aws_s3_bucket.transactions_codepipeline_bucket.arn}",
        "${aws_s3_bucket.transactions_codepipeline_bucket.arn}/*"
      ]
    }
    , {
        "Effect": "Allow",
        "Action": [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
        ],
        "Resource": [
            "*"
        ]
    }
  ]
}
POLICY
}
