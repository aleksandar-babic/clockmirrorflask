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

resource "aws_iam_role" "codepipeline" {
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

resource "aws_iam_role_policy" "codepipeline" {
  name = "s3_access"
  role = aws_iam_role.codepipeline.id

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
        "iam:PassRole",
        "ecs:*",
        "ecr:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "main" {
  name     = "${var.app_name}-${var.env}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner  = var.github_owner
        Repo   = var.github_repo
        Branch = var.github_repo_branch
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "StaticAnalysis"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["staticanalysis_output"]
      version          = "1"
      run_order        = "1"

      configuration = {
        ProjectName = aws_codebuild_project.static_analysis.name
      }
    }

    action {
      name             = "UnitTest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["unittest_output"]
      version          = "1"
      run_order        = "1"

      configuration = {
        ProjectName = aws_codebuild_project.unit_test.name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "DockerBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "DeployECR"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output", "build_output"]
      output_artifacts = ["deployecr_output"]
      version          = "1"
      run_order        = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.deploy_ecr.name
        PrimarySource = "source_output"
      }
    }

    action {
      name             = "DeployApp"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["deployapp_output"]
      version          = "1"
      run_order        = "2"

      configuration = {
        ProjectName = aws_codebuild_project.deploy_app.name
      }
    }

    action {
      name            = "UpdateECSService"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["deployecr_output"]
      version         = "1"
      run_order       = "3"

      configuration = {
        ClusterName = "${var.app_name}-${var.env}"
        ServiceName = "api"
      }
    }
  }
}