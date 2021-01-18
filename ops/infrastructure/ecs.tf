locals {
  nginx_container_name = "nginx"
  app_container_name = "app"
}

##########################################
# REPOSITORIES
##########################################
resource "aws_ecr_repository" "app" {
  name = var.service_name
}

resource "aws_ecr_repository" "app_nginx" {
  name = "${var.service_name}-nginx"
}

##########################################
# ECS SERVICE
##########################################
resource "aws_ecs_service" "app" {
  name            = var.service_name
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.arn
  cluster         = aws_ecs_cluster.common.id
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.private.*.id

    # Public ip assigned to the task as requested
    assign_public_ip = true

    security_groups = [aws_security_group.vpc.id]
  }

  # No load balancer in this test but MUST be the proper way
//  load_balancer {
//    container_name = ""
//    container_port = 0
//  }
}

# List all public subnet
data "aws_subnet_ids" "public" {
  vpc_id = aws_default_vpc.default.id
}

##########################################
# TASK DEFINITION
##########################################
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.service_name}-${var.environment}"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_task_role.arn
  container_definitions    = <<EOF
[
  {
    "name": "${local.nginx_container_name}",
    "image": "${aws_ecr_repository.app_nginx.repository_url}:${var.service_version}",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.nginx.name}",
        "awslogs-region": "${var.region}",
           "awslogs-stream-prefix": "${var.environment}"
      }
    },
    "dependsOn": [
      {
        "containerName": "${local.app_container_name}",
        "condition": "START"
      }
    ],
    "essential": true
},
  {
     "name": "${local.app_container_name}",
     "command": null,
     "entryPoint": null,
     "essential": true,
     "image": "${aws_ecr_repository.app.repository_url}:${var.service_version}",
     "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
           "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
           "awslogs-region": "${var.region}",
           "awslogs-stream-prefix": "${var.environment}"
        }
     },
     "portMappings": [
      {
        "hostPort": 9000,
        "protocol": "tcp",
        "containerPort": 9000
      }
    ],
     "environment": [
        {
            "name": "APP_ENV",
            "value": "${var.environment}"
        }, {
            "name": "DB_CONNECTION",
            "value": "sqlite"
        }
     ]
  }
]
EOF
}

# Retrieve `AmazonECSTaskExecutionRolePolicy` which contains the permissions, the common use cases
data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role (allows your Amazon ECS container task to make calls to other AWS services)
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.service_name}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_tasks.json
}

# Execution Task Role (the task execution role that the Amazon ECS container agent and the Docker daemon can assume)
resource "aws_iam_role" "ecs_execution_task_role" {
  name               = "${var.service_name}-${var.environment}-ecs-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_with_common_permissions" {
  role       = aws_iam_role.ecs_execution_task_role.name
  policy_arn = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn
}

data "aws_iam_policy_document" "assume_ecs_tasks" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
