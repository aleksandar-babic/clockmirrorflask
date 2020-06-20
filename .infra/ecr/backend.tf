terraform {
  backend "s3" {
    encrypt              = true
    key                  = "clockmirrorflask-ecr.tfstate"
    workspace_key_prefix = "clockmirrorflask-ecr"
  }
}