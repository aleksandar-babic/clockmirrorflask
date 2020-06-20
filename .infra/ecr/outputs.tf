output "ecr_repo_url" {
  value = aws_ecr_repository.clockmirrorflask.repository_url
}

output "ecr_repo_name" {
  value = aws_ecr_repository.clockmirrorflask.name
}

output "ecr_repo_arn" {
  value = aws_ecr_repository.clockmirrorflask.arn
}