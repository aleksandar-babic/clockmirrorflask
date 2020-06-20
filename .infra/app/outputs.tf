output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.clockmirrorflask.arn
}

output "ecs_service_api_id" {
  value = aws_ecs_service.api.id
}

output "alb_dns_name" {
  value = aws_alb.api.dns_name
}

output "alb_url" {
  value = "http://${aws_alb.api.dns_name}"
}