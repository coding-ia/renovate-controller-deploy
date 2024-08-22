variable "github_application_id" {
  description = "GitHub Application ID."
  type        = string
}

variable "github_application_webhook_secret" {
  description = "GitHub Application Webhook Secret."
  type        = string
  sensitive   = true
}

variable "github_enterprise_server" {
  description = "GitHub Enterprise Server."
  type        = bool
  default     = false
}

variable "github_enterprise_server_host" {
  description = "GitHub Application ID."
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  description = "ECS Cluster to run the tasks on."
  type        = string
}

variable "assign_public_ip_to_task" {
  description = "Assigns a public IP to the running task."
  type        = bool
  default     = true
}

variable "renovate_configuration_file" {
  description = "Renovate configuration file."
  type        = string
  default     = ""
}

variable "renovate_container_image" {
  description = "Renovate application docker image."
  type        = string
  default     = "renovate/renovate:38.30"
}

variable "renovate_controller_container_image" {
  description = "Renovate Controller docker image."
  type        = string
  default     = "ghcr.io/coding-ia/renovate-controller:1.0.0-1"
}

variable "subnets" {
  description = "VPC subnets to run ECS tasks."
  type        = list(string)
}

variable "schedule_expression" {
  description = "Schedule expression for Renovate task."
  type        = list(string)
  default     = "cron(0 5 * * ? *)"
}

variable "schedule_expression_timezone" {
  description = "Timezone for schedule expression."
  type        = list(string)
  default     = "UTC"
}
