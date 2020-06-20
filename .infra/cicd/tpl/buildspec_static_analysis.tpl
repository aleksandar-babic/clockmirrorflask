version: 0.2

env:
  variables:
    TERRAFORM_VERSION: "0.12.26"
    TERRAFORM_PATH: "/usr/local/bin"

phases:
  install:
    commands:
      - wget -q https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - unzip terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - rm -rf terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - mv terraform $${TERRAFORM_PATH}
      - pip3 install --upgrade flake8
  build:
    commands:
      - echo Static Analysis started on `date`
      - echo Terraform fmt
      - terraform fmt -check -recursive
      - echo Validating Terraform
      - terraform init -backend=false && terraform validate
      - echo Flake8 Python check
      - flake8 -v