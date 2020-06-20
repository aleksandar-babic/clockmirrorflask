version: 0.2

env:
  variables:
    DOCKER_IMAGE_NAME: ${image_name}

phases:
  build:
    commands:
      - echo Docker Build started on `date`
      - docker build -t $${DOCKER_IMAGE_NAME} .
      - docker save $${DOCKER_IMAGE_NAME} -o $${DOCKER_IMAGE_NAME}

artifacts:
  files:
    - $DOCKER_IMAGE_NAME
