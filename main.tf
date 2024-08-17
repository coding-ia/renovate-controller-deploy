locals {
  public_ip_enabled = var.assign_public_ip_to_task ? "true" : "false"
}

resource "aws_ecs_task_definition" "renovate" {
  container_definitions = jsonencode(
    [
      {
        command = [
          "task",
          "generate-config",
        ]
        environment = [
          {
            name  = "GITHUB_APPLICATION_ID"
            value = "${var.github_application_id}"
          },
          {
            name  = "GITHUB_APPLICATION_PRIVATE_PEM_AWS_SECRET"
            value = "${aws_secretsmanager_secret.github_application_pem.arn}"
          },
          {
            name  = "CONFIG_TEMPLATE_BUCKET"
            value = "${aws_s3_bucket.renovate.id}"
          },
          {
            name  = "CONFIG_TEMPLATE_KEY"
            value = "${aws_s3_object.object.id}"
          },
          {
            name  = "GENERATE_CONFIG_OUTPUT"
            value = "/data/${aws_s3_object.object.id}"
          },
        ]
        essential = false
        image     = "${var.renovate_controller_container_image}"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/renovate"
            awslogs-region        = "us-east-2"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
          secretOptions = []
        }
        mountPoints = [
          {
            containerPath = "/data"
            readOnly      = false
            sourceVolume  = "data"
          },
        ]
        name           = "init"
        portMappings   = []
        systemControls = []
        volumesFrom    = []
      },
      {
        dependsOn = [
          {
            condition     = "COMPLETE"
            containerName = "init"
          },
        ]
        environment = [
          {
            name  = "RENOVATE_CONFIG_FILE"
            value = "/data/${aws_s3_object.object.id}"
          },
        ]
        essential = true
        image     = "${var.renovate_container_image}"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/renovate"
            awslogs-region        = "us-east-2"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
          secretOptions = []
        }
        mountPoints = [
          {
            containerPath = "/data"
            readOnly      = true
            sourceVolume  = "data"
          },
        ]
        name           = "renovate"
        portMappings   = []
        systemControls = []
        volumesFrom    = []
      },
    ]
  )
  cpu                = "1024"
  execution_role_arn = "arn:aws:iam::211125334931:role/ecsTaskExecutionRole"
  family             = "renovate"
  memory             = "3072"
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  tags          = {}
  tags_all      = {}
  task_role_arn = aws_iam_role.renovate_task_role.arn
  track_latest  = false

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  volume {
    configure_at_launch = false
    name                = "data"
  }
}

resource "aws_ecs_task_definition" "renovate-controller" {
  container_definitions = jsonencode(
    [
      {
        command = [
          "task",
          "run",
        ]
        environment = [
          {
            name  = "AWS_ECS_CLUSTER_NAME"
            value = "${var.ecs_cluster_name}"
          },
          {
            name  = "AWS_ECS_CLUSTER_TASK"
            value = "${aws_ecs_task_definition.renovate.id}"
          },
          {
            name  = "AWS_ECS_TASK_PUBLIC_IP"
            value = "${local.public_ip_enabled}"
          },
          {
            name  = "GITHUB_APPLICATION_ID"
            value = "${var.github_application_id}"
          },
          {
            name  = "GITHUB_APPLICATION_PRIVATE_PEM_AWS_SECRET"
            value = "${aws_secretsmanager_secret.github_application_pem.name}"
          },
        ]
        environmentFiles = []
        essential        = true
        image            = "211125334931.dkr.ecr.us-east-2.amazonaws.com/renovate-controller:latest"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/renovate-controller"
            awslogs-region        = "us-east-2"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
          secretOptions = []
        }
        mountPoints    = []
        name           = "renovate-controller"
        portMappings   = []
        systemControls = []
        ulimits        = []
        volumesFrom    = []
      },
    ]
  )
  cpu                = "1024"
  execution_role_arn = "arn:aws:iam::211125334931:role/ecsTaskExecutionRole"
  family             = "renovate-controller"
  memory             = "3072"
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  tags          = {}
  tags_all      = {}
  task_role_arn = aws_iam_role.renovate_task_role.arn
  track_latest  = false

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_iam_role" "renovate_task_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
          Sid = ""
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Allows ECS tasks to call AWS services on your behalf."
  force_detach_policies = false
  managed_policy_arns   = []
  max_session_duration  = 3600
  name                  = "ecsTaskRenovateServiceRole"
  path                  = "/"
  tags                  = {}
  tags_all              = {}

  inline_policy {
    name = "permissions"
    policy = jsonencode(
      {
        Statement = [
          {
            Action   = "ec2:DescribeSubnets"
            Effect   = "Allow"
            Resource = "*"
            Sid      = "VisualEditor0"
          },
          {
            Action = [
              "s3:GetObject",
              "iam:PassRole",
              "secretsmanager:GetSecretValue",
              "ecs:RunTask",
            ]
            Effect = "Allow"
            Resource = [
              "${aws_secretsmanager_secret.github_application_pem.arn}",
              "${aws_s3_object.object.arn}",
              "arn:aws:iam::211125334931:role/*",
              "arn:aws:ecs:*:211125334931:task-definition/*:*",
            ]
            Sid = "VisualEditor1"
          },
        ]
        Version = "2012-10-17"
      }
    )
  }
}

resource "aws_s3_bucket" "renovate" {
  bucket_prefix = "renovate-controller-"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.renovate.id
  key    = "config.js"
  source = "config.js"

  etag = filemd5("config.js")
}

resource "aws_secretsmanager_secret" "github_application_pem" {
  force_overwrite_replica_secret = false
  name                           = "renovate/github/app/privateKey"
  recovery_window_in_days        = 0
}

resource "aws_secretsmanager_secret_version" "pem_contents" {
  secret_id     = aws_secretsmanager_secret.github_application_pem.id
  secret_string = file("application.pem")
}
