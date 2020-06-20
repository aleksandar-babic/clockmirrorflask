resource "aws_default_vpc" "main" {}

resource "aws_default_subnet" "main" {
  for_each = toset(var.ecs_service_subnets_to_use)

  availability_zone = "${var.region}${each.value}"
}