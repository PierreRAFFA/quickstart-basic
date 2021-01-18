resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/${var.service_name}-nginx-${var.environment}"
  retention_in_days = 30
}