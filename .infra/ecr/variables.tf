variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Region where AWS provider will be initialized."
}

variable "env" {
  type        = string
  description = "Environment where resources will be deployed"
}

variable "app_ecr_repo_name" {
  type        = string
  default     = "clockmirrorflask"
  description = "Name of the ECR repo that will hold app docker image."
}

variable "ecr_images_to_keep" {
  type        = number
  default     = 5
  description = "Amount of images to be kept in the ECR repo."
}