data "aws_ecr_repository" "app" {
  name = var.ecr_repo_name
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.env}"
}

resource "aws_ecs_task_definition" "clockmirrorflask" {
  family                   = var.app_name
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.app_name}",
      "image": "${data.aws_ecr_repository.app.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${var.ecs_task_port},
          "hostPort": ${var.ecs_task_port}
        }
      ],
      "memory": ${var.ecs_task_memory},
      "cpu": ${var.ecs_task_cpu}
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = var.ecs_task_memory
  cpu                      = var.ecs_task_cpu
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.clockmirrorflask.arn
  launch_type     = "FARGATE"
  desired_count   = var.ecs_service_api_desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = aws_ecs_task_definition.clockmirrorflask.family
    container_port   = var.ecs_task_port
  }

  network_configuration {
    subnets          = [for s in aws_default_subnet.main : s.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }
}

resource "aws_security_group" "ecs_service" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}