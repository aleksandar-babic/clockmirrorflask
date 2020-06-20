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

variable "codebuild_env_image" {
  type        = string
  description = "Docker image that will be used in Codebuild"
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
}

variable "github_owner" {
  type        = string
  description = "Owner of the GitHub repo"
  default     = "aleksandar-babic"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name"
  default     = "clockmirrorflask"
}

variable "github_repo_branch" {
  type        = string
  description = "GitHub repo build branch"
  default     = "master"
}

variable "tf_state_bucket" {
  type        = string
  description = "Name of the remote state S3 bucket"
}

variable "codebuild_compute_type" {
  type = string
  description = "Compute type used in Codebuilds"
  default = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_build_timeout" {
  type = string
  description = "Timeout used in Codebuilds"
  default = "15"
}