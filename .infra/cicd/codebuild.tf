data "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket
}

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
    tf_state_bucket = data.aws_s3_bucket.tf_state.id
    tf_region       = var.region
  }
}

data "template_file" "buildspec_deploy_app" {
  template = file("${path.module}/tpl/buildspec_deploy_app.tpl")

  vars = {
    env             = var.env
    ecr_repo        = "${var.app_name}-${var.env}"
    tf_state_bucket = data.aws_s3_bucket.tf_state.id
    tf_region       = var.region
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
          "Effect":"Allow",
          "Action": [
            "s3:*"
          ],
          "Resource": [
            "${aws_s3_bucket.codepipeline_artifacts.arn}",
            "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
            "${data.aws_s3_bucket.tf_state.arn}",
            "${data.aws_s3_bucket.tf_state.arn}/*"
          ]
        },
        {
            "Action": [
                "logs:*",
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
          "Effect":"Allow",
          "Action": [
            "s3:*"
          ],
          "Resource": [
            "${aws_s3_bucket.codepipeline_artifacts.arn}",
            "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
            "${data.aws_s3_bucket.tf_state.arn}",
            "${data.aws_s3_bucket.tf_state.arn}/*"
          ]
        },
        {
            "Action": [
                "logs:*",
                "ecr:*",
                "ecs:*",
                "ec2:*",
                "iam:*",
                "elasticloadbalancing:*"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "AllowDeployApp"
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

resource "aws_iam_role_policy" "codebuild_base" {
  role   = aws_iam_role.codebuild_base.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect":"Allow",
          "Action": [
            "s3:*"
          ],
          "Resource": [
            "${aws_s3_bucket.codepipeline_artifacts.arn}",
            "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
          ]
        },
        {
            "Action": [
                "logs:*"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "AllowBase"
        }
    ]
}
EOF
}

resource "aws_codebuild_project" "static_analysis" {
  name          = "${var.app_name}-${var.env}-static-analysis"
  service_role  = aws_iam_role.codebuild_base.arn
  build_timeout = var.codebuild_build_timeout
  description   = "Static analysis stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
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
  build_timeout = var.codebuild_build_timeout
  description   = "Unit Test stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
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
  build_timeout = var.codebuild_build_timeout
  description   = "Build stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
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
  build_timeout = var.codebuild_build_timeout
  description   = "Deploy stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
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
  build_timeout = var.codebuild_build_timeout
  description   = "Deploy stage of ${var.app_name}-${var.env} component."

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
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

