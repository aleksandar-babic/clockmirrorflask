variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Region where AWS provider will be initialized."
}

variable "env" {
  type        = string
  description = "Environment where resources will be deployed"
}

variable "app_name" {
  type        = string
  description = "Name of the app"
  default     = "clockmirrorflask"
}

variable "ecs_task_memory" {
  type        = number
  description = "Memory to give to the ecs task"
  default     = 512
}

variable "ecs_task_cpu" {
  type        = number
  description = "CPU to give to the ecs task"
  default     = 256
}

variable "ecs_task_port" {
  type        = number
  description = "Port on which the app runs"
  default     = 8080
}

variable "ecr_repo_name" {
  type        = string
  description = "Name of the app ECR repo to lookup"
}

variable "ecr_repo_tag" {
  type        = string
  description = "ECR Repo tag to use"
}

variable "ecs_service_api_desired_count" {
  type        = number
  description = "Number of desired count for the API service"
  default     = 1
}

variable "ecs_service_subnets_to_use" {
  type        = list(string)
  description = "List of default subnets to use"
  default     = ["a", "b", "c"]
}

variable "alb_sg_ingress_port" {
  type        = number
  description = "Allowed ingress port for ALB"
  default     = 80
}

variable "alb_sg_ingress_cidr_blocks" {
  type        = list(string)
  description = "Allowed ingress cidrs"
  default     = ["0.0.0.0/0"]
}