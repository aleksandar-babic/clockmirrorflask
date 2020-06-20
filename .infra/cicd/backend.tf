terraform {
  backend "s3" {
    encrypt              = true
    key                  = "clockmirrorflask-cicd.tfstate"
    workspace_key_prefix = "clockmirrorflask-cicd"
  }
}