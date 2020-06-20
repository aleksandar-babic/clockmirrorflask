resource "aws_alb" "api" {
  name               = "${var.app_name}-${var.env}"
  load_balancer_type = "application"
  subnets            = [for s in aws_default_subnet.main : s.id]
  security_groups    = [aws_security_group.alb.id]
}


resource "aws_security_group" "alb" {
  ingress {
    from_port   = var.alb_sg_ingress_port
    to_port     = var.alb_sg_ingress_port
    protocol    = "tcp"
    cidr_blocks = var.alb_sg_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "api" {
  depends_on = [aws_alb.api]

  name        = "api-${var.app_name}-${var.env}"
  port        = var.alb_sg_ingress_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_alb.api.arn
  port              = var.alb_sg_ingress_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}