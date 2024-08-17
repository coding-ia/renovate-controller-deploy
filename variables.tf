variable "github_application_id" {
  description = "GitHub Application ID."
  type        = string
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

variable "renovate_container_image" {
  description = "Renovate application docker image."
  type        = string
  default     = "renovate/renovate:38.30"
}

variable "renovate_controller_container_image" {
  description = "Renovate Controller docker image."
  type        = string
  default     = "ghcr.io/coding-ia/renovate-controller:1.0.0"
}

variable "subnets" {
  description = "VPC subnets to run ECS tasks."
  type        = list(string)
}
