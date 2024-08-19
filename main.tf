data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  public_ip_enabled = var.assign_public_ip_to_task ? "true" : "false"
  server_host       = var.github_enterprise_server ? var.github_enterprise_server_host : "api.github.com"
  renovate_config   = var.renovate_configuration_file == "" ? "${path.module}/config.js" : var.renovate_configuration_file
  account_id        = data.aws_caller_identity.current.account_id
  region            = data.aws_region.current.name
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
            name  = "GITHUB_APPLICATION_ENDPOINT"
            value = "${local.server_host}"
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
            awslogs-region        = "${local.region}"
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
            awslogs-region        = "${local.region}"
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
  execution_role_arn = aws_iam_role.renovate_task_execution_role.arn
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

resource "aws_ecs_task_definition" "renovate_controller" {
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
          {
            name  = "GITHUB_APPLICATION_ENDPOINT"
            value = "${local.server_host}"
          }
        ]
        environmentFiles = []
        essential        = true
        image            = "${var.renovate_controller_container_image}"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/renovate-controller"
            awslogs-region        = "${local.region}"
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
  execution_role_arn = aws_iam_role.renovate_task_execution_role.arn
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

data "aws_subnet" "selected" {
  id = var.subnets[0]
}

resource "aws_security_group" "renovate_task" {
  description = "Attach to renovate tasks"
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description = ""
      from_port   = 0
      ipv6_cidr_blocks = [
        "::/0",
      ]
      prefix_list_ids = []
      protocol        = "-1"
      security_groups = []
      self            = false
      to_port         = 0
    },
  ]
  ingress = []
  name    = "renovate-task"
  tags = {
    "renovate" = "true",
  }
  tags_all = {}
  vpc_id   = data.aws_subnet.selected.vpc_id
}

resource "aws_iam_role" "renovate_task_execution_role" {
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
      Version = "2008-10-17"
    }
  )
  force_detach_policies = false
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
  max_session_duration = 3600
  name                 = "ecsRenovateTaskExecutionRole"
  path                 = "/"
  tags                 = {}
  tags_all             = {}
}

resource "aws_iam_role_policy_attachment" "renovate_task_execution_policy_attach" {
  role       = aws_iam_role.renovate_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
  max_session_duration  = 3600
  name                  = "ecsRenovateTaskRole"
  path                  = "/"
  tags                  = {}
  tags_all              = {}
}

resource "aws_iam_policy" "renovate_task_role_policy" {
  name_prefix = "Renovate-Task-Policy-"
  path        = "/"
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
          Action   = "ecs:RunTask"
          Effect   = "Allow"
          Resource = "${aws_ecs_task_definition.renovate.arn_without_revision}:*"
          Sid      = "VisualEditor1"
        },
        {
          Action = "iam:PassRole"
          Effect = "Allow"
          Resource = [
            "${aws_iam_role.renovate_task_role.arn}",
            "${aws_iam_role.renovate_task_execution_role.arn}",
          ]
          Sid = "VisualEditor2"
        },
        {
          Action   = "secretsmanager:GetSecretValue"
          Effect   = "Allow"
          Resource = "${aws_secretsmanager_secret.github_application_pem.arn}"
          Sid      = "VisualEditor3"
        },
        {
          Action   = "s3:GetObject"
          Effect   = "Allow"
          Resource = "${aws_s3_object.object.arn}"
          Sid      = "VisualEditor4"
        },
      ]
      Version = "2012-10-17"
    }
  )
  tags     = {}
  tags_all = {}
}

resource "aws_iam_role_policy_attachment" "renovate_task_policy_attach" {
  role       = aws_iam_role.renovate_task_role.name
  policy_arn = aws_iam_policy.renovate_task_role_policy.arn
}

resource "aws_s3_bucket" "renovate" {
  bucket_prefix = "renovate-controller-"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.renovate.id
  key    = "config.js"
  source = local.renovate_config

  etag = filemd5(local.renovate_config)
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

data "aws_ecs_cluster" "selected_ecs_cluster" {
  cluster_name = var.ecs_cluster_name
}

resource "aws_scheduler_schedule" "renovate_schedule" {
  group_name                   = "default"
  name                         = "Renovate"
  schedule_expression          = "rate(4 hours)"
  schedule_expression_timezone = "America/Los_Angeles"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = data.aws_ecs_cluster.selected_ecs_cluster.arn
    role_arn = aws_iam_role.aws_scheduler_schedule_role.arn

    ecs_parameters {
      enable_ecs_managed_tags = true
      enable_execute_command  = false
      launch_type             = "FARGATE"
      tags                    = {}
      task_count              = 1
      task_definition_arn     = aws_ecs_task_definition.renovate_controller.arn

      network_configuration {
        assign_public_ip = var.assign_public_ip_to_task
        security_groups = [
          aws_security_group.renovate_task.id
        ]
        subnets = var.subnets
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = 86400
      maximum_retry_attempts       = 0
    }
  }
}

resource "aws_iam_role" "aws_scheduler_schedule_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = local.account_id
            }
          }
          Effect = "Allow"
          Principal = {
            Service = "scheduler.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name_prefix           = "Amazon_EventBridge_Scheduler_ECS_"
  path                  = "/service-role/"
  tags                  = {}
  tags_all              = {}
}

resource "aws_iam_policy" "eventbridge_schedule_managed_policy" {
  name_prefix = "Amazon-EventBridge-Scheduler-Execution-Policy-"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ecs:RunTask",
          ]
          Condition = {
            ArnLike = {
              "ecs:cluster" = data.aws_ecs_cluster.selected_ecs_cluster.arn
            }
          }
          Effect = "Allow"
          Resource = [
            "${aws_ecs_task_definition.renovate_controller.arn_without_revision}:*",
            "${aws_ecs_task_definition.renovate_controller.arn_without_revision}",
          ]
        },
        {
          Action = "iam:PassRole"
          Condition = {
            StringLike = {
              "iam:PassedToService" = "ecs-tasks.amazonaws.com"
            }
          }
          Effect = "Allow"
          Resource = [
            "*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
  tags     = {}
  tags_all = {}
}

resource "aws_iam_role_policy_attachment" "eventbridge_schedule_role_policy_attach" {
  role       = aws_iam_role.aws_scheduler_schedule_role.name
  policy_arn = aws_iam_policy.eventbridge_schedule_managed_policy.arn
}

resource "aws_lambda_function" "renovate_webhook_controller" {
  architectures = [
    "x86_64",
  ]
  filename                       = "renovate-webhook-controller.zip"
  function_name                  = "renovate-webhook-controller"
  handler                        = "bootstrap"
  layers                         = []
  memory_size                    = 128
  package_type                   = "Zip"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.renovate_webhook_controller_role.arn
  runtime                        = "provided.al2"
  skip_destroy                   = false
  source_code_hash               = filesha256("renovate-webhook-controller.zip")
  tags                           = {}
  tags_all                       = {}
  timeout                        = 300

  environment {
    variables = {
      "AWS_ECS_CLUSTER_NAME"   = "${var.ecs_cluster_name}"
      "AWS_ECS_CLUSTER_TASK"   = "${aws_ecs_task_definition.renovate.id}"
      "AWS_ECS_TASK_PUBLIC_IP" = "${local.public_ip_enabled}"
      "GITHUB_APPLICATION_ID"  = "${var.github_application_id}"
      "WEBHOOK_SECRET"         = "${var.github_application_webhook_secret}"
    }
  }

  ephemeral_storage {
    size = 512
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/renovate-webhook-controller"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_iam_role" "renovate_webhook_controller_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name_prefix           = "renovate-webhook-controller-role-"
  path                  = "/service-role/"
  tags                  = {}
  tags_all              = {}

  inline_policy {
    name = "RenovateWebhookControllerPermissions"
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
              "iam:PassRole",
              "ecs:RunTask",
            ]
            Effect = "Allow"
            Resource = [
              "${aws_ecs_task_definition.renovate.arn_without_revision}:*",
              "${aws_iam_role.renovate_task_role.arn}",
              "${aws_iam_role.renovate_task_execution_role.arn}",
            ]
            Sid = "VisualEditor1"
          },
        ]
        Version = "2012-10-17"
      }
    )
  }
}

resource "aws_iam_policy" "renovate_webhook_controller_managed_policy" {
  name_prefix = "AWSLambdaBasicExecutionRole-"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action   = "logs:CreateLogGroup"
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:${local.account_id}:*"
        },
        {
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:*:${local.account_id}:log-group:${aws_lambda_function.renovate_webhook_controller.logging_config[0].log_group}:*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
  tags     = {}
  tags_all = {}
}

resource "aws_iam_role_policy_attachment" "renovate_webhook_controller_role_policy_attach" {
  role       = aws_iam_role.renovate_webhook_controller_role.name
  policy_arn = aws_iam_policy.renovate_webhook_controller_managed_policy.arn
}
