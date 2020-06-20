resource "aws_ecr_repository" "clockmirrorflask" {
  name = "${var.app_ecr_repo_name}-${var.env}"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "pytest_expire" {
  repository = aws_ecr_repository.clockmirrorflask.name
  policy     = <<EOF
{
  "rules": [
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": ${var.ecr_images_to_keep},
        "tagStatus": "any"
      },
      "description": "Keep only ${var.ecr_images_to_keep} latest images",
      "rulePriority": 1
    }
  ]
}
  EOF
}