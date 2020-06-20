terraform {
  backend "s3" {
    encrypt              = true
    key                  = "clockmirrorflask-app.tfstate"
    workspace_key_prefix = "clockmirrorflask-app"
  }
}