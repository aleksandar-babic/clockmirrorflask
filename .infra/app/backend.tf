terraform {
  backend "s3" {
    encrypt              = true
    region               = "eu-west-1"
    key                  = "clockmirrorflask-app.tfstate"
    workspace_key_prefix = "clockmirrorflask-app"
  }
}