## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.63.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_task_definition.renovate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.renovate_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.eventbridge_schedule_managed_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.renovate_webhook_controller_managed_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aws_scheduler_schedule_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.renovate_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.renovate_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.renovate_webhook_controller_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.eventbridge_schedule_role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.renovate_task_execution_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.renovate_webhook_controller_role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.renovate_webhook_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_bucket.renovate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_object.object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_scheduler_schedule.renovate_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_secretsmanager_secret.github_application_pem](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.pem_contents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_cluster.selected_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip_to_task"></a> [assign\_public\_ip\_to\_task](#input\_assign\_public\_ip\_to\_task) | Assigns a public IP to the running task. | `bool` | `true` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | ECS Cluster to run the tasks on. | `string` | n/a | yes |
| <a name="input_github_application_id"></a> [github\_application\_id](#input\_github\_application\_id) | GitHub Application ID. | `string` | n/a | yes |
| <a name="input_github_application_webhook_secret"></a> [github\_application\_webhook\_secret](#input\_github\_application\_webhook\_secret) | GitHub Application Webhook Secret. | `string` | n/a | yes |
| <a name="input_github_enterprise_server"></a> [github\_enterprise\_server](#input\_github\_enterprise\_server) | GitHub Enterprise Server. | `bool` | `false` | no |
| <a name="input_github_enterprise_server_host"></a> [github\_enterprise\_server\_host](#input\_github\_enterprise\_server\_host) | GitHub Application ID. | `string` | `""` | no |
| <a name="input_renovate_container_image"></a> [renovate\_container\_image](#input\_renovate\_container\_image) | Renovate application docker image. | `string` | `"renovate/renovate:38.30"` | no |
| <a name="input_renovate_controller_container_image"></a> [renovate\_controller\_container\_image](#input\_renovate\_controller\_container\_image) | Renovate Controller docker image. | `string` | `"ghcr.io/coding-ia/renovate-controller:1.0.0"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | VPC subnets to run ECS tasks. | `list(string)` | n/a | yes |

## Outputs

No outputs.
