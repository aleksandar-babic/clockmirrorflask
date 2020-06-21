version: 0.2

env:
  variables:
    TERRAFORM_VERSION: "0.12.26"
    TERRAFORM_PATH: "/usr/local/bin"
    TERRAFORM_STATE_BUCKET: ${tf_state_bucket}
    DOCKER_IMAGE_NAME: ${image_name}
    APP_NAME: ${app_name}
    TF_VAR_region: ${tf_region}
    TF_VAR_env: ${env}

phases:
  install:
    commands:
      - wget -q https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - unzip terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - rm -rf terraform_$${TERRAFORM_VERSION}_linux_amd64.zip
      - mv terraform $${TERRAFORM_PATH}
      - pip3 install --user --upgrade jq

  pre_build:
    commands:
      - echo "Logging in to Amazon ECR"
      - $(aws ecr get-login --no-include-email --region $TF_VAR_region)
      - echo "Loading Docker image"
      - cd $CODEBUILD_SRC_DIR_build_output
      - docker load -i $${DOCKER_IMAGE_NAME}

  build:
    commands:
      - echo ECR Deploy started on `date`
      - cd $CODEBUILD_SRC_DIR/.infra/ecr
      - terraform init -backend-config="bucket=$${TERRAFORM_STATE_BUCKET}" -backend-config="region=$${TF_VAR_region}"
      - terraform workspace select $${TF_VAR_env} || terraform workspace new $${TF_VAR_env}
      - terraform apply -input=false --auto-approve
      - terraform output -json > output.json
      - export repo_url=$(cat output.json | jq -r '.ecr_repo_url.value')
      - docker tag $${DOCKER_IMAGE_NAME} $${repo_url}:latest
      - docker tag $${DOCKER_IMAGE_NAME} $${repo_url}:$${CODEBUILD_RESOLVED_SOURCE_VERSION}

  post_build:
    commands:
      - echo ECR Deploy completed on `date`
      - echo "Pushing Docker image"
      - docker push $${repo_url}:latest
      - docker push $${repo_url}:$${CODEBUILD_RESOLVED_SOURCE_VERSION}
      - >
       echo "[{\"name\": \"$${APP_NAME}\", \"imageUri\": \"$${repo_url}:$${CODEBUILD_RESOLVED_SOURCE_VERSION}\"}]" > /tmp/imagedefinitions.json

artifacts:
  files:
    - /tmp/imagedefinitions.json
  discard-paths: yes