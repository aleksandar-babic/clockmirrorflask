data "template_file" "buildspec_static_analysis" {
  template = file("${path.module}/tpl/buildspec_static_analysis.tpl")
}

data "template_file" "buildspec_unit_test" {
  template = file("${path.module}/tpl/buildspec_unit_test.tpl")
}

data "template_file" "buildspec_build" {
  template = file("${path.module}/tpl/buildspec_build.tpl")
  vars = {
    image_name = "${var.app_name}-${var.env}"
  }
}

data "template_file" "buildspec_deploy_ecr" {
  template = file("${path.module}/tpl/buildspec_deploy_ecr.tpl")

  vars = {
    image_name      = "${var.app_name}-${var.env}"
    env             = var.env
    tf_state_bucket = var.tf_state_bucket
  }
}

data "template_file" "buildspec_deploy_app" {
  template = file("${path.module}/tpl/buildspec_deploy_app.tpl")

  vars = {
    env             = var.env
    ecr_repo        = "${var.app_name}-${var.env}"
    tf_state_bucket = var.tf_state_bucket
  }
}

resource "aws_iam_role" "codebuild_deploy_ecr" {
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "CodebuildServiceAssumeAllow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_deploy_ecr" {
  role   = aws_iam_role.codebuild_deploy_ecr.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:*"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "AllowDeployEcr"
        }
    ]
}
EOF
}

resource "aws_iam_role" "codebuild_deploy_app" {
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "CodebuildServiceAssumeAllow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_deploy_app" {
  role   = aws_iam_role.codebuild_deploy_app.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:*",
                "ecs:*",
                "iam:*",
                "elasticloadbalancing:*"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "AllowDeployApp"
        },
        {
            "Action": [
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcs"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "AllowVPCRO"
        }
    ]
}
EOF
}

resource "aws_iam_role" "codebuild_base" {
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "CodebuildServiceAssumeAllow"
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "static_analysis" {
  name          = "${var.app_name}-${var.env}-static-analysis"
  service_role  = aws_iam_role.codebuild_base.arn
  build_timeout = "15"
  description   = "Static analysis stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_env_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec_static_analysis.rendered
  }

  lifecycle {
    ignore_changes = [tags["CreatorName"]]
  }
}

resource "aws_codebuild_project" "unit_test" {
  name          = "${var.app_name}-${var.env}-unit-test"
  service_role  = aws_iam_role.codebuild_base.arn
  build_timeout = "15"
  description   = "Unit Test stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_env_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }


  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec_unit_test.rendered
  }

  lifecycle {
    ignore_changes = [tags["CreatorName"]]
  }
}

resource "aws_codebuild_project" "build" {
  name          = "${var.app_name}-${var.env}-build"
  service_role  = aws_iam_role.codebuild_base.arn
  build_timeout = "15"
  description   = "Build stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_env_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec_build.rendered
  }

  lifecycle {
    ignore_changes = [tags["CreatorName"]]
  }
}

resource "aws_codebuild_project" "deploy_ecr" {
  name          = "${var.app_name}-${var.env}-deploy-ecr"
  service_role  = aws_iam_role.codebuild_deploy_ecr.arn
  build_timeout = "15"
  description   = "Deploy stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_env_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec_deploy_ecr.rendered
  }

  lifecycle {
    ignore_changes = [tags["CreatorName"]]
  }
}

resource "aws_codebuild_project" "deploy_app" {
  name          = "${var.app_name}-${var.env}-deploy-app"
  service_role  = aws_iam_role.codebuild_deploy_app.arn
  build_timeout = "15"
  description   = "Deploy stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_env_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec_deploy_app.rendered
  }

  lifecycle {
    ignore_changes = [tags["CreatorName"]]
  }
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  force_destroy = true
  acl           = "private"

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatorName"]]
  }
}

