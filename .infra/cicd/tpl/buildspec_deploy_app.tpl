version: 0.2

env:
  variables:
    TERRAFORM_VERSION: "0.12.26"
    TERRAFORM_PATH: "/usr/local/bin"
    TERRAFORM_STATE_BUCKET: ${tf_state_bucket}
    TF_VAR_region: ${tf_region}
    TF_VAR_env: ${env}
    TF_VAR_ecr_repo_name: ${ecr_repo}

phases:
  install:
    commands:
      - wget -q https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - unzip terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - rm -rf terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - mv terraform $${TERRAFORM_PATH}

  build:
    commands:
      - echo App Deploy started on `date`
      - cd .infra/app
      - terraform init -backend-config="bucket=$${TERRAFORM_STATE_BUCKET}" -backend-config="region=$${TF_VAR_region}"
      - terraform workspace select $${TF_VAR_env} || terraform workspace new $${TF_VAR_env}
      - terraform apply -input=false --auto-approve